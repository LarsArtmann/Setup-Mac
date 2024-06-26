command=$@
$command &&
echo "Added "$command" locally"
echo "$command" >> step2.zsh &&
echo "Backup old Brewfile..." &&
mv Brewfile "$(shasum Brewfile | tr '  ' '_')" ||
echo "Dump new Brewfile..." &&
brew bundle dump &&
echo "Git commit..." &&
git commit -am "$command" &&
echo "Git push..." &&
git push &&
echo "Added "$command" git"
