#!/bin/sh

#How to use -> COOKIES='user.id=...;_intra_42_session_production=...' ./sub.sh
#Cookies to be found in a web browser with intra42 opened, under dev tools -> Network tab -> request cookies


COOKIES=${COOKIES?-'No cookies!'}

projects=$(curl -s 'https://projects.intra.42.fr/projects/list' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0' -H 'Cookie: '"$COOKIES" |\
    xmllint --html --xpath '//a[starts-with(@href, "/projects")]/@href' - 2>/dev/null |\
    cut -d\" -f2 |\
    sort -u)

# Create a lock file
lockfile="/tmp/download_lock"

# Function to acquire the lock
acquire_lock() {
    while [! -e "$lockfile" ]; do
        touch "$lockfile"
        sleep 1
    done
}

# Function to release the lock
release_lock() {
    rm -f "$lockfile"
}

# Acquire the lock before starting downloads
acquire_lock

for project in $projects; do
    (
        pdf=$(curl -s 'https://projects.intra.42.fr/'$project -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0' -H 'Cookie: '"$COOKIES" |\
            xmllint --html --xpath '//a[text()="subject.pdf"]/@href' - 2>/dev/null |\
            cut -d\" -f2)
        echo $project...
        curl -s "$pdf" -o ${project##/projects/}.pdf
    ) &

    # Wait for the background process to finish before releasing the lock
    wait
    release_lock
done

