#!/bin/bash
​
MODE="$1"
RAILSDIR="/tmp/rb-rails"
​
if [ "x$MODE" == "x" ]; then
  echo "Invalid mode: community (c) or enterprise (e)"
  exit 1
fi
​
echo "Copying ~/rb-rails dir ... "
​
rm -rf $RAILSDIR
mkdir -p $RAILSDIR
​
#rsync -a /root/trunk/manager/core/var/www/rb-rails/ $RAILSDIR
rsync -a ~/rb-rails/ $RAILSDIR
​
echo "Generating dittoc ..."
​
if [ "x$MODE" == "xe" ]; then
  rsync -a /root/trunk/manager/core.enterprise/var/www/rb-rails/* $RAILSDIR
  #rsync -a /root/versions/master/manager/core.enterprise/var/www/rb-rails/* $RAILSDIR
  dittoc -r -o -f --allow-views ENTERPRISE $RAILSDIR
elif [ "x$MODE" == "xc" ]; then
  sed -i '/rinruby/d' $RAILSDIR/Gemfile
  rm -rf $RAILSDIR/lib/modules/malware
  rm -rf $RAILSDIR/lib/modules/aalicense
  rm -rf $RAILSDIR/lib/modules/location
  dittoc -r -o -f --allow-views COMMUNITY $RAILSDIR
fi

if [ "x$MODE" != "xs" ]; then
  pushd $RAILSDIR &>/dev/null
  echo "Realocating assets ..."
  env NO_MODULES=1 RAILS_ENV=production bundle exec rake redBorder:move_assets_module
​
  if [ "x$MODE" == "xe" ]; then
    echo "Coding rails directory ..."
    #rubyencoder --ruby 2.0 -b- --external rB.lic --projkey redBorder-Horama --projid 3.0 @rubyencoder.conf &>/dev/null
    rubyencoder --ruby 2.0 -b- --external rB.lic --projkey redBorder-Horama --projid 3.0 lib/modules/aalicense/lib/* &>/dev/null
    rm -f rubyencoder.conf
  fi
​
  echo "Compiling assets ..."
  rm -rf .git*
  rm -rf public/assets/*
  RAILS_ENV=production bundle exec rake assets:precompile
  pushd config &>/dev/null
  rm -f aerospike.yml aws.yml chef_config.yml coordinator_rules.yml databags.yml database.yml flow_rbdruid_config.yml iot_rbdruid_config.yml ips_rbdruid_config.yml knife.rb location_rbdruid_config.yml log-rotate malware_rbdruid_config.yml managers.yml memcached_config.yml modules.yml monitor_rbdruid_config.yml newrelic.yml nmsp_config.yml rbdruid_config.yml redborder_config.yml social_rbdruid_config.yml sysconfig unicorn.rb users_service.yml zendesk.yml
  popd &>/dev/null
  rm -f rB.lic
  rm -rf logs/*
  chown -R rb-webui:rb-webui $RAILSDIR $RAILSDIR/lib/assets/images/
  mkdir -p tmp
  touch tmp/restart.txt
  popd &>/dev/null
fi
​
shift

if [ "x$*" != "x" ]; then
  for n in $*; do
    echo "Rsync to $n ..."
    #rsync -ar -e "ssh -p 6666 -i /root/.ssh/id_rsa" --delete $RAILSDIR/* root@$n:rb-rails
    rsync -ar --delete $RAILSDIR/* root@$n:rb-rails
    #echo "Rsync assets to $n ..."
    #rsync -ar -e "ssh -i /root/.ssh/id_rsa" --delete -a $RAILSDIR/public/assets root@$n:rb-rails/public/
    #[ -d $RAILSDIR/app/assets ] && rsync -ar -e "ssh -i /root/.ssh/id_rsa" --delete -a $RAILSDIR/app/assets root@$n:rb-rails/app/
    #[ -d $RAILSDIR/lib/assets ] && rsync -ar -e "ssh -i /root/.ssh/id_rsa" --delete -a $RAILSDIR/lib/assets root@$n:rb-rails/lib/
  done
fi

