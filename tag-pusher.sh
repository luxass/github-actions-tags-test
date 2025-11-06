#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <mode> <tag1> [tag2] [tag3] ...

Modes:
  direct    - Create and push each tag immediately
  batch     - Create all tags first, then push them all at once

Examples:
  $0 direct v1.0.0 v1.0.1 v1.0.2
  $0 batch v2.0.0 v2.0.1 v2.0.2

EOF
    exit 1
}

# Check if at least mode and one tag are provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Not enough arguments${NC}"
    usage
fi

MODE=$1
shift
TAGS=("$@")

# Validate mode
if [ "$MODE" != "direct" ] && [ "$MODE" != "batch" ]; then
    echo -e "${RED}Error: Invalid mode '$MODE'. Must be 'direct' or 'batch'${NC}"
    usage
fi

echo -e "${GREEN}Mode: $MODE${NC}"
echo -e "${GREEN}Tags to create: ${TAGS[*]}${NC}"
echo ""

# Function to create a tag
create_tag() {
    local tag=$1
    echo -e "${YELLOW}Creating tag: $tag${NC}"
    if git tag "$tag"; then
        echo -e "${GREEN}✓ Tag '$tag' created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create tag '$tag'${NC}"
        return 1
    fi
}

# Function to push a tag
push_tag() {
    local tag=$1
    echo -e "${YELLOW}Pushing tag: $tag${NC}"
    if git push origin "$tag"; then
        echo -e "${GREEN}✓ Tag '$tag' pushed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to push tag '$tag'${NC}"
        return 1
    fi
}

# Direct mode: create and push each tag immediately
if [ "$MODE" = "direct" ]; then
    echo -e "${GREEN}=== Direct Mode: Creating and pushing tags one by one ===${NC}"
    echo ""

    for tag in "${TAGS[@]}"; do
        if create_tag "$tag"; then
            push_tag "$tag"
        else
            echo -e "${RED}Stopping due to tag creation failure${NC}"
            exit 1
        fi
        echo ""
    done

    echo -e "${GREEN}=== All tags created and pushed successfully! ===${NC}"

# Batch mode: create all tags first, then push them all
elif [ "$MODE" = "batch" ]; then
    echo -e "${GREEN}=== Batch Mode: Creating all tags first ===${NC}"
    echo ""

    # Create all tags
    CREATED_TAGS=()
    for tag in "${TAGS[@]}"; do
        if create_tag "$tag"; then
            CREATED_TAGS+=("$tag")
        else
            echo -e "${RED}Stopping due to tag creation failure${NC}"
            exit 1
        fi
    done

    echo ""
    echo -e "${GREEN}=== Pushing all tags in batch ===${NC}"
    echo ""

    # Push all created tags at once
    echo -e "${YELLOW}Pushing tags: ${CREATED_TAGS[*]}${NC}"
    if git push origin "${CREATED_TAGS[@]}"; then
        echo -e "${GREEN}✓ All tags pushed successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to push tags${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}=== All tags created and pushed successfully! ===${NC}"
fi