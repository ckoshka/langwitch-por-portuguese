#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UDHR_LANG_CODE="spa"
CLIENT_LANG_CODE="es"
SOURCE_CORPUS="oscar"

for cmd in $(deno run -A clients/client_all.ts --lang=${CLIENT_LANG_CODE} --source=${SOURCE_CORPUS})
do
    eval $cmd \
    | ./tools/lengthfilter.rs \
        --min_words 20 \
        --max_words 1000000 \
    | ./tools/sentences.rs --reject_uncapitalized \
    | grep '[[:punct:]]$' \
    | grep -vE '(www|\@)' \
    | ./tools/lengthfilter.rs \
        --max_chars 100 \
    | ./tools/deduplicate.rs \
    | ./tools/sort.rs \
        --min 0.95 \
    | ./tools/langfilter.rs \
        --reference_files languages_udhr \
        --desired_lang languages_udhr/${UDHR_LANG_CODE}.html \
        --min_confidence 0.85 \
    | ./tools/clean.rs \
        --no_punctuation \
    | ./tools/deduplicate.rs \
        --no_punct \
    | ./tools/translate.rs --to "en" --keep --concurrency 80 \
    | ./tools/nosame.rs \
    | head -n 600000 > /dev/stdout
done

# ./fetch.sh | pv -l --size 600000 -F "%p %t %e %a" > gathered/romance_languages/french/oscar/data.tsv