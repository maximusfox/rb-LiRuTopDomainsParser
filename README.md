# rb-LiRuTopDomainsParser
Simple ruby script for parsing domain names from Liveinternet.ru top

# Install dependecies

Install all gems without bundler
```
grep '^gem' ./Gemfile | cut -d\' -f2 | xargs -n1 sudo gem install
```


# Download domains list

```
chmod +x ./main.rb
./main.rb
```
```
wc -l ./domains.txt
129330 ./domains.txt
```
