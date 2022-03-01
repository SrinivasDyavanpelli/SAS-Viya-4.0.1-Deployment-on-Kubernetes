#!/bin/bash

echo "------------Viya 4 - Architecture - Slides"
find "/Users/canepg/SAS/" -type d | \
    grep -E 'PSGEL266' | sort | \
    sed 's|\/Users\/canepg\/SAS\/\/GEL\ Workshop\ \-\ ||g'
find "/Users/canepg/SAS/" -name "*.pptx" | \
    grep -E 'PSGEL266' | sort | \
    sed 's|\/Users\/canepg\/SAS\/\/GEL\ Workshop\ \-\ ||g'

echo ""

echo "------------Viya 4 - Deployment - Slides"
find "/Users/canepg/SAS/" -name "*.pptx" | \
    grep -E 'PSGEL255' | sort | \
    sed 's|\/Users\/canepg\/SAS\/\/GEL\ Workshop\ \-\ ||g'

echo ""


echo "------------Viya 4 - Deployment - Hands-On"
find "/Users/canepg/Documents/git_projects/gitlab/PSGEL255-deploying-viya-4.0.1-on-kubernetes/" \
    -name "*.md" | awk -F'//' '{print $2}' | grep  -E -v 'dev/|scripts/' | sort

echo ""


echo "------------Viya 4 - Admin - Slides"
find "/Users/canepg/SAS/" -name "*.pptx" | \
    grep -E 'PSGEL260' | sort | \
    sed 's|\/Users\/canepg\/SAS\/\/GEL\ Workshop\ \-\ ||g'

echo ""

echo "------------Viya 4 - Admin - Hands-On"
find "/Users/canepg/Documents/git_projects/gitlab/PSGEL260-sas-viya-4.0.1-administration/" \
    -name "*.md" | awk -F'//' '{print $2}' | grep  -E -v 'dev/' | sort

# changes made