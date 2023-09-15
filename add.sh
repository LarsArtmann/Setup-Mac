command=$1
echo $command >> step2.sh &&
git -am $command &&
git push &&
exec $command
echo $command added :)
