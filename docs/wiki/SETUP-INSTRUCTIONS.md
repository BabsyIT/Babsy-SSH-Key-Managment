# Wiki Setup Instructions

## 📝 So richten Sie das Wiki ein:

### Schritt 1: Wiki aktivieren (GitHub Web UI)

```bash
1. Gehe zu: https://github.com/BabsyIT/Babsy-SSH-Key-Managment
2. Klick auf "Settings" (Zahnrad-Icon)
3. Scroll runter zu "Features"
4. ✅ Häkchen bei "Wikis"
5. Klick "Save"
```

### Schritt 2: Wiki klonen

```bash
# Wiki Repository klonen (separates Git Repo!)
git clone https://github.com/BabsyIT/Babsy-SSH-Key-Managment.wiki.git
cd Babsy-SSH-Key-Managment.wiki
```

### Schritt 3: Wiki-Inhalte kopieren

```bash
# Aus diesem Repository
cd /pfad/zu/Babsy-SSH-Key-Managment

# Wiki-Dateien kopieren
cp docs/wiki/*.md ../Babsy-SSH-Key-Managment.wiki/

# Oder manuell via GitHub UI (siehe Alternative unten)
```

### Schritt 4: Wiki committen und pushen

```bash
cd ../Babsy-SSH-Key-Managment.wiki

# Dateien hinzufügen
git add *.md

# Committen
git commit -m "Initial wiki setup - Complete documentation"

# Pushen
git push origin master
```

### Schritt 5: Wiki ansehen

```bash
# Im Browser öffnen:
https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki
```

---

## 🔄 Alternative: Via GitHub UI (ohne Git)

Falls Sie Git nicht für das Wiki verwenden möchten:

### Schritt 1-2: Wie oben (Wiki aktivieren)

### Schritt 3: Home Page erstellen

```bash
1. Gehe zu Wiki Tab
2. Klick "Create the first page"
3. Title: "Home"
4. Content: Kopiere Inhalt aus docs/wiki/Home.md
5. Klick "Save Page"
```

### Schritt 4: Weitere Seiten erstellen

```bash
Für jede Datei in docs/wiki/:

1. Klick "New Page"
2. Title: z.B. "Production Deployment"
3. Content: Kopiere Inhalt aus docs/wiki/Production-Deployment.md
4. Klick "Save Page"

Wiederholen für:
- Production-Deployment.md → "Production Deployment"
- Troubleshooting.md → "Troubleshooting"
- (weitere Dateien...)
```

---

## 📋 Wiki-Seiten die erstellt werden sollten:

Aus `docs/wiki/`:

1. ✅ **Home.md** → Wiki Startseite
2. ✅ **Production-Deployment.md** → Komplette Setup-Anleitung
3. ✅ **Troubleshooting.md** → Problemlösung

Weitere Seiten die noch erstellt werden können:
- GitHub-Actions-Setup.md
- M365-Integration.md
- Ansible-Configuration.md
- GitHub-Secrets-Configuration.md
- Security-Best-Practices.md
- Monitoring-Logging.md
- User-Management.md
- SSH-Keys-Configuration.md
- Sudo-Configuration.md
- Separate-Authorized-Keys.md
- etc.

Sollen ich die weiteren Wiki-Seiten auch erstellen?

---

## 🎨 Wiki Sidebar (Optional)

Für bessere Navigation:

```bash
# In Wiki Repository
cd Babsy-SSH-Key-Managment.wiki

# _Sidebar.md erstellen
cat > _Sidebar.md <<'EOF'
### 🏠 Navigation

**Getting Started**
- [Home](Home)
- [Production Deployment](Production-Deployment)

**Configuration**
- [GitHub Actions Setup](GitHub-Actions-Setup)
- [M365 Integration](M365-Integration)
- [Ansible Configuration](Ansible-Configuration)

**Operations**
- [Monitoring & Logging](Monitoring-Logging)
- [Troubleshooting](Troubleshooting)

**Security**
- [Security Best Practices](Security-Best-Practices)
- [GitHub Secrets](GitHub-Secrets-Configuration)
EOF

git add _Sidebar.md
git commit -m "Add wiki sidebar"
git push
```

---

## ✅ Fertig!

Ihr Wiki ist jetzt unter erreichbar:
**https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki**
