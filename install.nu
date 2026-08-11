#!/usr/bin/env nu

let src = ($"($env.FILE_PWD)/github-dashboard")
let dst = ($env.HOME | path join ".local" "share" "noctalia" "plugins" "github-dashboard")

mkdir ($dst | path dirname)
rm -rf $dst
cp -r $src $dst

noctalia msg plugins enable denunciated/github-dashboard
noctalia msg config-reload

print "Installed denunciated/github-dashboard"
print "Add the github widget in Noctalia, or open it with:"
print "  noctalia msg panel-toggle denunciated/github-dashboard:dashboard"

