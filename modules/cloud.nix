{ config, lib, pkgs, ... }:

# All hosts: rclone remotes for cloud storage, mounted under ~/clouds/<name>.
# Tokens are secrets, so they live outside the repo in ~/.config/rclone-secrets/
# and are copied into ~/.config/rclone/rclone.conf on each switch.
{
	home-manager.users.james = { config, lib, ... }:
		let
			tokenFile = "${config.home.homeDirectory}/.config/rclone-secrets/pcloud-token";
		in
		{
			programs.rclone = {
				enable = true;
				remotes.pcloud = {
					config = {
						type = "pcloud";
						hostname = "eapi.pcloud.com"; # EU region
					};
					mounts."/" = {
						enable = true;
						mountPoint = "${config.home.homeDirectory}/clouds/pCloud";
						# Keep the local file cache small (default is unlimited).
						options.vfs-cache-max-size = "2G";
					};
				};
			};

			# Not the module's own `secrets` option: that fails the switch if the file is
			# missing. Here a machine without the token still switches, and the mount fails
			# until the token is added.
			home.activation.rclonePcloudToken = lib.hm.dag.entryAfter [ "createRcloneConfig" ] ''
				if [ -r "${tokenFile}" ]; then
					run ${lib.getExe config.programs.rclone.package} config update pcloud \
						config_refresh_token=false token "$(cat "${tokenFile}")" \
						--quiet --non-interactive > /dev/null
				else
					echo "rclone: no pCloud token at ${tokenFile}, skipping."
				fi
			'';
		};
}
