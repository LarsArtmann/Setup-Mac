command=$@
zsh "$command" &&
echo "Added "$command" locally"
echo "$command" >> step2.zsh &&
git commit -am "$command" &&
git push &&
echo "Added "$command" git"
