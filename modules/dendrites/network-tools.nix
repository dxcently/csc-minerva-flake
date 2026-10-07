# network-tools — defensive network diagnosis and monitoring: see what is on the
# wire, what is listening, where a path breaks, and what a peer exposes.
{
  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Capture and inspection
        tcpdump
        tshark
        ngrep
        # Path and reachability
        mtr
        traceroute
        iperf3
        # Scanning and probing
        nmap
        socat
        netcat-openbsd
        # Interfaces, firewall and state
        ethtool
        conntrack-tools
        nftables
        iproute2
        bridge-utils
        # Names and TLS
        dnsutils
        whois
        openssl
        # Live traffic views
        iftop
        nethogs
        bandwhich
        # Tunnels
        wireguard-tools
      ];

      # Capture without root, for wheel members only.
      programs.wireshark.enable = true;
      programs.wireshark.package = pkgs.tshark;
    };
}
