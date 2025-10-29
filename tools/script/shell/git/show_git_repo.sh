#!/bin/bash

# Find all .git directories, get their worktree root path and remote URL,
# then output the path and URL separated by a pipe.
find . -type d -name ".git" -exec sh -c '
    REPO_PATH="{}";
    DIR_PATH=$(dirname "$REPO_PATH");
    URL=$(git -C "$DIR_PATH" remote get-url origin 2>/dev/null);

    if [ -n "$URL" ]; then
        echo "$DIR_PATH|$URL";
    fi
' \; | \
sort | \
awk -F'|' '
    BEGIN {
        # Print the root node
        print ".";
        # Array to track if a vertical line (|) is needed at a given depth
        for(i=1; i<20; i++) branch[i]=0;

        # Array to store the path segments for each line
        # This is needed because the "split" command in the loop resets the array on each iteration
        delete segments;
    }

    # Store all data first to determine last siblings later
    { data[NR] = $0 }

    END {
        # 1. Determine the "is_last" status for each path
        for(i = 1; i <= NR; i++) {
            split(data[i], fields, "|");
            # Split path into segments (e.g., [., openwrt, feeds, mtk_openwrt_feed])
            num_segments = split(fields[1], segments[i], "/");
            depth[i] = num_segments;
            is_last[i] = 1; # Assume last by default

            # Check the next line to see if this is truly the last sibling
            if (i < NR) {
                split(data[i+1], next_fields, "|");

                # Compare the parent directory of the current item with the parent of the next item
                # The parent is everything but the last path segment (which is the repo folder name)

                # Extract the parent path up to the *repo folder name* (the part before .git)
                parent_path_current = fields[1]; sub(/\/[^\/]*$/, "", parent_path_current);
                parent_path_next = next_fields[1]; sub(/\/[^\/]*$/, "", parent_path_next);

                if (parent_path_current == parent_path_next) {
                    is_last[i] = 0; # Not the last sibling
                }
            }
        }

        # 2. Iterate and draw the tree
        last_printed_parent = "";

        for (i = 1; i <= NR; i++) {
            # Re-split the current path for printing segments
            split(data[i], fields, "|");
            full_path = fields[1];
            url = fields[2];

            # Re-split the path into segments for indentation logic
            delete current_segments;
            num_segments = split(full_path, current_segments, "/");

            # --- Intermediate Directory Printing ---
            # Loop through path segments, excluding the root '.' and the final repo name
            current_path_prefix = ".";
            for (j = 2; j < num_segments; j++) {
                current_path_prefix = current_path_prefix "/" current_segments[j];

                # Check if this directory node has already been printed
                if (current_path_prefix != last_printed_parent) {
                    output = "";
                    # Apply indentation for vertical lines of the *grandparents*
                    for (k = 2; k < j; k++) {
                        # 0 = vertical line, 1 = space
                        output = output (branch[k] == 0 ? "│   " : "    ");
                    }

                    # Prefix for the directory node itself
                    # We use ├── because only the *last* .git will be └──
                    prefix = "├── ";

                    print output prefix current_segments[j];
                }
            }

            # --- Final .git Node Printing ---

            output = "";
            # Apply indentation for vertical lines of the *parent directories*
            for (j = 2; j < num_segments; j++) {
                output = output (branch[j] == 0 ? "│   " : "    ");
            }

            # Determine prefix for the actual .git node
            prefix = (is_last[i] == 1) ? "└── " : "├── ";

            # Print the repo name and the URL
            repo_dir_name = current_segments[num_segments];
            print output prefix repo_dir_name " (" url ")";

            # If this was the last sibling in its directory, close the vertical line for that depth
            if (is_last[i] == 1) {
                # Close the branch at the parent level (num_segments - 1)
                branch[num_segments - 1] = 1;
            }

            last_printed_parent = full_path;
        }
    }
'
