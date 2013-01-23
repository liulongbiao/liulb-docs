#!/bin/sh
echo do translating ...
find . -name "*.md" -print | xargs multimarkdown -b
echo translate multimarkdown file to html has finished 