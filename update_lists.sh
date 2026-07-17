#!/bin/bash

# Định nghĩa đường dẫn tương đối trong Github Workspace
DIR="rules"
BLOCK_OUT="./$DIR/blocklists.txt"
ALLOW_OUT="./$DIR/allowlists.txt"
BLOCK_TMP="/tmp/blocklists.tmp"
ALLOW_TMP="/tmp/allowlists.tmp"

# Tạo thư mục rules nếu chưa có
mkdir -p "./$DIR"

# Cleanup khi script exit
trap "rm -f $BLOCK_TMP $ALLOW_TMP; exit" INT TERM EXIT

extract_domains() {
  awk '{
    if (/^[[:space:]]*$/ || /^[!#]/) next
    line = tolower($0)
    sub(/^@@\|\|?/, "", line)
    sub(/^\|\|?/, "", line)
    sub(/\^.*/, "", line)
    sub(/[#!].*/, "", line)
    sub(/\/.*/, "", line)
    sub(/:.*/, "", line)
    sub(/^[0-9.]+[[:space:]]+/, "", line)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (line ~ /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$/ && !seen[line]++) print line
  }'
}

echo "Downloading and processing blocklists..."

> "$BLOCK_TMP"

for url in \
"https://raw.githubusercontent.com/nextdns/click-tracking-domains/main/domains" \
"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/popupads-onlydomains.txt" \
"https://raw.githubusercontent.com/bigdargon/hostsVN/master/extensions/threat/hosts-VN" \
"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/tif.mini-onlydomains.txt" \
"https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
do
    echo "Downloading: $url"

    if curl -fsSL --max-time 60 "$url" | extract_domains >> "$BLOCK_TMP"; then
        echo "✓ Success"
    else
        echo "✗ Failed"
    fi
done

sort -u "$BLOCK_TMP" -o "$BLOCK_TMP"

echo "Downloading and processing allowlists..."

> "$ALLOW_TMP"

for url in \
"https://raw.githubusercontent.com/bibicadotnet/AdGuard-Home-blocklists/main/whitelist.txt" \
"https://raw.githubusercontent.com/nextdns/click-tracking-domains/main/domains" \
"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/allow.txt"
do
    echo "Downloading: $url"

    if curl -fsSL --max-time 60 "$url" | extract_domains >> "$ALLOW_TMP"; then
        echo "✓ Success"
    else
        echo "✗ Failed"
    fi
done

sort -u "$ALLOW_TMP" -o "$ALLOW_TMP"

# Di chuyển file tmp vào thư mục đích
mv "$BLOCK_TMP" "$BLOCK_OUT"
mv "$ALLOW_TMP" "$ALLOW_OUT"

echo "Done. Files saved to $BLOCK_OUT and $ALLOW_OUT"
