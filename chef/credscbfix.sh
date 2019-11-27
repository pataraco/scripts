#!/bin/bash
# quick and dirty script to update "data_bag_item" lines in the cookbooks that use them

cd /home/praco/repos/cookbooks
for recipe in `grep -rl "data_bag_item(\"aws\", \"credentials\")\[\"environments\"\]\[node\[:app_environment\]\]"`; do
   cookbook=`echo $recipe | cut -d'/' -f1`
   echo "working on $cookbook::$recipe"
   cd $cookbook
   tmpdir=`dirname $recipe`
   mkdir -p /tmp/$tmpdir
   hg pull -u
   cd -
   sed 's^data_bag_item("aws", "credentials").*:app_environment]]^data_bag_item("aws", "credentials")["environments"][node[:app_environment]][node.dns.vpc][node.dns.site]^g' $recipe > /tmp/$recipe.new
   diff $recipe /tmp/$recipe.new
   cp $recipe /tmp/$recipe.orig
   echo -n "going to change the recipe - hit enter to continue"
   read junk
   cp /tmp/$recipe.new $recipe
   echo -n "going to verify bookmarks - hit enter to continue"
   read junk
   cd $cookbook
   hg update devtest
   devtest_rev=`hg bookmarks|grep devtest|awk '{print $NF}'|cut -d':' -f1`
   production_rev=`hg bookmarks|grep production|awk '{print $NF}'|cut -d':' -f1`
   publictest_rev=`hg bookmarks|grep publictest|awk '{print $NF}'|cut -d':' -f1`
   if [ $devtest_rev -eq $publictest_rev -a $publictest_rev -eq $production_rev ]; then
      echo "all bookmarks are at the same level - going to commit and push up all"
   echo -n "going to commit and push - hit enter to continue"
   read junk
      hg commit -m "changing the way we get the databag info for aws credentials"
      hg push -B devtest
      hg bookmark publictest
      hg push -B publictest
      hg bookmark production
      hg push -B production
   else
      echo "all bookmarks are NOT at the same level - NOT going to commit and push up all"
      echo "take care of this yourself!"
   fi
   #read junk
   #rm -r /tmp/$cookbook
   cd -
done

