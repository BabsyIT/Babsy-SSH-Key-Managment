#!/bin/bash
# =============================================================================
# Babsy IT - GitHub Username Extension Attribute Setup (Linux Version)
# =============================================================================
# Dieses Script setzt für alle IT-Team Mitglieder den GitHub-Username
# in extensionAttribute1 (wird für SSH-Key-Management verwendet)
#
# WICHTIG: extensionAttribute1 = GitHub Username (interne Konvention)
# =============================================================================

set -e

echo "================================================"
echo "Babsy IT - GitHub Username Setup für Entra ID"
echo "================================================"
echo ""

# Prüfe ob Azure CLI installiert ist
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI ist nicht installiert!"
    echo ""
    echo "Installation für Linux Mint/Ubuntu:"
    echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo ""
    exit 1
fi

# Mit Azure anmelden
echo "🔐 Melde dich bei Azure an..."
az login

echo ""
echo "✓ Erfolgreich angemeldet!"
echo ""

# User-Mapping: E-Mail -> GitHub Username
declare -A users=(
    ["stefan@babsy.ch"]="stefan-ffr"
    ["oliver@babsy.ch"]="oliverbabsy"
)

declare -A fullnames=(
    ["stefan@babsy.ch"]="Stefan Müller"
    ["oliver@babsy.ch"]="Oliver Jucker"
)

echo "📝 Setze GitHub-Usernames in extensionAttribute1..."
echo "================================================"
echo ""

# Extension Attribute für jeden User setzen
for email in "${!users[@]}"; do
    github_username="${users[$email]}"
    fullname="${fullnames[$email]}"

    echo "Verarbeite: $fullname ($email)"

    # Setze extensionAttribute1 via Microsoft Graph API
    result=$(az rest \
        --method PATCH \
        --url "https://graph.microsoft.com/v1.0/users/$email" \
        --headers "Content-Type=application/json" \
        --body "{\"onPremisesExtensionAttributes\": {\"extensionAttribute1\": \"$github_username\"}}" \
        2>&1)

    if [ $? -eq 0 ]; then
        echo "  ✓ extensionAttribute1 gesetzt: $github_username"
    else
        echo "  ✗ Fehler beim Setzen"
        echo "  $result"
    fi

    echo ""
done

echo "================================================"
echo "Setup abgeschlossen!"
echo "================================================"
echo ""

# Verifiziere die Einstellungen
echo "📋 Aktuelle GitHub-Usernames (extensionAttribute1):"
echo "================================================"
echo ""

for email in "${!users[@]}"; do
    fullname="${fullnames[$email]}"

    echo "$fullname:"
    echo "  E-Mail: $email"

    # Lese extensionAttribute1 aus
    github_username=$(az rest \
        --method GET \
        --url "https://graph.microsoft.com/v1.0/users/$email?$select=onPremisesExtensionAttributes" \
        --query "onPremisesExtensionAttributes.extensionAttribute1" \
        -o tsv 2>/dev/null)

    if [ -n "$github_username" ]; then
        echo "  GitHub: $github_username"
    else
        echo "  GitHub: (nicht gesetzt)"
    fi

    echo ""
done

echo "✓ Fertig! Die GitHub-Usernames sind jetzt in Entra ID gespeichert."
echo "  Das M365-Sync Script kann nun diese Werte auslesen."
echo ""
