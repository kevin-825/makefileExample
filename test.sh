#!/bin/bash
echo hello 
while getopts "a::b" opt; do
  case $opt in
    a)
      if [[ -n $OPTARG ]]; then
        echo "Option -a with argument: $OPTARG"
      else
        # Check if the next positional parameter is part of another option
        nextarg="${!OPTIND}"
        if [[ -n $nextarg && $nextarg != -* ]]; then
          echo "Option -a with argument: $nextarg"
          OPTIND=$((OPTIND + 1)) # Consume the next argument
        else
          echo "Option -a with no argument"
        fi
      fi
      ;;
    b)
      echo "Option -b triggered"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $((OPTIND - 1))
echo "Remaining arguments: $@"
