command=$@
echo "$command" >> step2.sh &&
git commit -am "$command" &&
git push &&
exec "$command"
echo "$command added :)"

