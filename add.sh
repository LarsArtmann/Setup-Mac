command=$@
zsh "$command" &&
echo "$command added locally"
echo "$command" >> step2.sh &&
git commit -am "$command" &&
git push &&
echo "$command added to git"
