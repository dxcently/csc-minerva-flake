# hardening — the host's own defences, beyond the nucleus's key-only SSH and
# default-deny firewall: ban repeat SSH offenders, tighten the kernel's network
# and information surfaces, restrict privilege escalation, keep logs bounded,
# and audit what runs as root.
{
  nixos =
    { lib, pkgs, ... }:
    {
      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
        bantime-increment.enable = true;
        # Never ban the private ranges the operators come from.
        ignoreIP = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
        ];
      };

      boot.kernel.sysctl = {
        # Network: no redirects, no source routing, strict reverse path, log martians.
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.tcp_syncookies" = 1;
        # Information leaks and attack surface.
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
        "kernel.yama.ptrace_scope" = 1;
        "fs.protected_hardlinks" = 1;
        "fs.protected_symlinks" = 1;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
      };
      # Strict rp_filter breaks a subnet router's asymmetric paths; Tailscale's
      # routing features set it loosely where needed, so only default it here.
      networking.firewall.checkReversePath = lib.mkDefault "strict";
      networking.firewall.logRefusedConnections = true;

      boot.blacklistedKernelModules = [
        "dccp"
        "sctp"
        "rds"
        "tipc"
        "cramfs"
        "freevxfs"
        "jffs2"
        "hfs"
        "hfsplus"
        "udf"
      ];

      security.sudo.execWheelOnly = true;
      security.auditd.enable = true;
      security.audit = {
        enable = true;
        rules = [
          "-a exit,always -F arch=b64 -F euid=0 -S execve -k root-exec"
          "-w /etc/ssh/sshd_config -p wa -k sshd-config"
          "-w /run/secrets -p r -k secrets-read"
        ];
      };

      services.journald.settings.Journal = {
        SystemMaxUse = "1G";
        MaxRetentionSec = "1month";
      };

      nix.settings.allowed-users = [ "@wheel" ];
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      environment.systemPackages = with pkgs; [
        lynis
        vulnix
      ];
    };
}
