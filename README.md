# 🛡️ Script de durcissement esprit ANSSI – Debian 12 (version robuste avec log)

## 🔍 Objectif :
Appliquer les recommandations ANSSI niveau standard sur une Debian 12 fraîche, avec journalisation complète dans `/var/log/durcissement.log`.

---

## 🔧 Étapes réalisées :

1. **Mise à jour du système**
   - `apt update && apt upgrade`

2. **Suppression des services obsolètes/inutiles**
   - Telnet, rsh, tftp, xinetd, etc.

3. **Nettoyage système**
   - `autoremove`, `autoclean`

4. **Installation des outils de sécurité**
   - `aide`, `auditd`, `apparmor`, `fail2ban`, `ufw`, `needrestart`

5. **Initialisation d'AIDE**
   - Création de la base d'intégrité `/var/lib/aide/aide.db`

6. **Configuration d’auditd**
   - Surveillance : `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, `execve`
   - Chargement des règles via `augenrules`

7. **Activation Fail2Ban**
   - Protection du SSH (4 essais max, ban 1h)

8. **Configuration UFW (pare-feu)**
   - Tout bloquer sauf SSH (`22/tcp`)
   - `ufw enable`

9. **Activation AppArmor**
   - Mise en mode `enforce` de tous les profils AppArmor

10. **Nettoyage des fichiers world-writable**
    - Suppression du bit `o+w` sur tous les fichiers critiques

11. **Alerte comptes sans mot de passe**
    - Audit via `/etc/shadow`

12. **Désactivation des modules noyau sensibles**
    - `usb-storage`, `firewire-core`, `bluetooth` → blacklistés

13. **Application d’un profil sysctl ANSSI**
    - ASLR, protection réseau, désactivation IPv6, etc.
    - Chargement via `sysctl --system`

14. **Traçabilité des actions bash (commandes tapées)**
    - Journalisation via `logger` + `rsyslog` → `/var/log/bash_audit.log`

15. **Log détaillé sudo**
    - Fichier : `/var/log/sudo.log`
    - Enregistrement des entrées/sorties (clavier/écran)

16. **Checklist finale**
    - Affiche toutes les étapes réussies et échouées
    - Stocke tout dans `/var/log/[NOM_DU_SCRIPT].log`

---

## 📦 Résultat final :

- ✅ Système durci ANSSI
- 🔒 Services réseau et modules restreints
- 📋 Audit permanent des actions système
- 📂 Log détaillé des actions dans `/var/log/durcissement.log`

---

## ❗ Ne modifie **pas** :
- Configuration SSH 
