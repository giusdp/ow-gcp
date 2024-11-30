
wsk -i action delete first

cd bench/first
zip -q -r first.zip *
wsk -i action update first --kind nodejs:14 first.zip -a tag data
rm first.zip

echo "Action 'first' created"

cd .. /..