#!/bin/bash

LOGFILE="/var/log/durcissement.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo -e "\n===== [ $(date '+%Y-%m-%d %H:%M:%S') ] Lancement du durcissement ANSSI ====="

OK=()
FAIL=()

step() {
  echo -e "\n🔧 $1"
  STEP_DESC="$1"
}

try() {
  "$@" >/dev/null 2>&1 && OK+=("$STEP_DESC") || FAIL+=("$STEP_DESC")
}

# === MISE À JOUR & NETTOYAGE ===
step "Mise à jour système"
try apt update && apt upgrade -y

step "Suppression des paquets obsolètes"
try apt purge -y telnet rsh-client rsh-server talk talkd xinetd tftp tftpd rlogin rsh

step "Nettoyage système"
try apt autoremove -y && apt autoclean -y

# === OUTILS DE SÉCURITÉ ===
step "Installation outils : aide, auditd, apparmor, etc."
try apt install -y aide aide-common auditd sudo ufw fail2ban apparmor apparmor-utils needrestart

step "Initialisation AIDE"
try aideinit && mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# === AUDITD ===
step "Configuration auditd (fichiers sensibles + execve)"
cat <<EOF > /etc/audit/rules.d/anssi.rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group  -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes
-a always,exit -F arch=b64 -S execve -k exec_tracking
-a always,exit -F arch=b32 -S execve -k exec_tracking
EOF
step "Activation auditd"
try augenrules --load && systemctl enable auditd --now

# === FAIL2BAN ===
step "Configuration Fail2Ban SSH"
cat <<EOF > /etc/fail2ban/jail.d/debian.local
[sshd]
enabled = true
maxretry = 4
bantime = 3600
EOF
try systemctl enable fail2ban --now

# === UFW ===
step "Configuration UFW (deny in, allow out + SSH)"
try ufw default deny incoming && ufw default allow outgoing && ufw allow 22/tcp && echo y | ufw enable

# === APPARMOR ===
step "Activation AppArmor"
try aa-enforce /etc/apparmor.d/*

# === NETTOYAGE FICHIERS WRITABLE ===
step "Nettoyage fichiers world-writable"
try find / -xdev -type f -perm -0002 -exec chmod o-w {} \;

step "Vérification comptes sans mot de passe"
try awk -F: '($2==""){print $1}' /etc/shadow

# === MODULES KERNEL ===
step "Blacklist modules noyau inutiles"
cat <<EOF > /etc/modprobe.d/anssi-blacklist.conf
blacklist usb-storage
blacklist firewire-core
blacklist bluetooth
install usb-storage /bin/false
install firewire-core /bin/false
install bluetooth /bin/false
EOF

# === SYSCTL DURCI ===
step "Application profil sysctl ANSSI"
cat <<EOF > /etc/sysctl.d/99-anssi.conf
kernel.randomize_va_space = 2
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
try sysctl --system

# === TRAÇABILITÉ ===
step "Journalisation des commandes shell bash"
echo 'export PROMPT_COMMAND='\''RETRN_VAL=$?;logger -p local1.notice -t bash_audit -- "$(whoami) [$$]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")"'\''' >> /etc/bash.bashrc

step "Log bash → rsyslog"
cat <<EOF > /etc/rsyslog.d/90-bash-audit.conf
local1.*    /var/log/bash_audit.log
EOF
touch /var/log/bash_audit.log
try systemctl restart rsyslog

step "Log sudo détaillé"
cat <<EOF > /etc/sudoers.d/logging
Defaults logfile="/var/log/sudo.log"
Defaults log_input,log_output
EOF
try chmod 440 /etc/sudoers.d/logging

# === CHECKLIST ===
echo -e "\n===================== ✅ CHECKLIST FINAL ====================="
echo -e "\n✅ Succès :"
for item in "${OK[@]}"; do echo "  ✔ $item"; done

echo -e "\n❌ Échecs :"
for item in "${FAIL[@]}"; do echo "  ✘ $item"; done

echo -e "\n📦 Durcissement terminé — $((${#OK[@]})) réussis / $((${#OK[@]} + ${#FAIL[@]})) total"
echo -e "🗂️  Rapport : $LOGFILE"
