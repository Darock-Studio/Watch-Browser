#!/bin/bash

if [[ "$CI_WORKFLOW" == *" Beta" ]]; then
  brew install jq
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir $TESTFLIGHT_DIR_PATH
  response=$(curl -s -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/Darock-Studio/Watch-Browser/commits/$CI_COMMIT")
  committer_name=$(echo "$response" | jq -r '.commit.committer.name')
  commit_date=$(echo "$response" | jq -r '.commit.committer.date')
  commit_message=$(echo "$response" | jq -r '.commit.message')
  additions=$(echo "$response" | jq -r '.stats.additions')
  deletions=$(echo "$response" | jq -r '.stats.deletions')
  changed_file_count=$(echo "$response" | jq -r '.files | length')
  changed_files=""
  for file in $(echo "$response" | jq -c '.files[]'); do
    changed_files+="    - $(echo "$file" | jq -r '.filename')"
  done
  xcodebuild_version=$(xcodebuild -version)
  swver=$(sw_vers)
  swver=${swver//$'ProductName:		'/}
  swver=${swver//$'\nProductVersion:		'/ }
  swver=${swver//$'\nBuildVersion:		'/(}
  swver+=")"
  echo -e "CI 自动构建的暗礁浏览器 Beta 更新

提交：$CI_COMMIT
提交者：$committer_name
提交日期：$commit_date
提交信息：
    ${commit_message//$'\n'/    \n}
$changed_file_count 个文件被更改, $additions 个添加(+), $deletions 个删除(-)
被更改的文件：
$changed_files

前往 https://github.com/Darock-Studio/Watch-Browser/commit/$CI_COMMIT 以查看完整提交信息

构建启动条件：$CI_START_CONDITION
工作流程 ID：$CI_WORKFLOW_ID
构建环境：
${xcodebuild_version//$'\nBuild version '/(})
$swver" > $TESTFLIGHT_DIR_PATH/WhatToTest.zh-Hans.txt
  echo -e "Darock Browser update built by CI automatically

Beta version of Darock Browser may contain incomplete localization.

Commit：$CI_COMMIT
Committer：$committer_name
Commit Date：$commit_date
Commit Message：
    ${commit_message//$'\n'/    \n}
$changed_file_count files changed, $additions additions(+), $deletions deletions(-)
Files Changed：
$changed_files

Visit https://github.com/Darock-Studio/Watch-Browser/commit/$CI_COMMIT for full commit information.

Building Start Condition：$CI_START_CONDITION
Workflow ID：$CI_WORKFLOW_ID
Building Environment：
${xcodebuild_version//$'\nBuild version '/(})
$swver" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
fi
