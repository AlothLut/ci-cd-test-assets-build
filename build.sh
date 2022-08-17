#!/bin/bash
set -euo pipefail

export DIFF_FILES=${DIFF_FILES}
export CI_PROJECT_DIR=${CI_PROJECT_DIR}
export ASSETS_DIR=$(find ${CI_PROJECT_DIR} -type d -name "assets" -print)
export ALL_ASSETS=$(find ${ASSETS_DIR} -type f -print)
mkdir -p ${CI_PROJECT_DIR}/builds
PREV_FILE=""

for FILE_PATH in ${DIFF_FILES}
do
    echo $FILE_PATH
    FILE_NAME="$(basename -- $FILE_PATH)"
    if [ -f "${FILE_PATH%%.*}.json" ]; then # condition for Bundle
        if [ "${PREV_FILE}" == "${FILE_NAME}" ];then
            continue
        fi
        PREV_FILE=$FILE_NAME
        ROTATE=$(jq ".rotate" ${FILE_PATH%%.*}.json)

        if [ "$ROTATE" == "\"right\"" ]; then
            if [ -f "${FILE_PATH%%.*}.jpg" ]; then
                convert "${FILE_PATH%%.*}.jpg" -rotate 90 "${FILE_PATH%%.*}.png"
            else
                convert "${FILE_PATH%%.*}.png" -rotate 90 "${FILE_PATH%%.*}.png"
            fi
        fi

        if [ "$ROTATE" == "\"left\"" ]; then
            if [ -f "${FILE_PATH%%.*}.jpg" ]; then
                convert "${FILE_PATH%%.*}.jpg" -rotate -90 "${FILE_PATH%%.*}.png"
            else
                convert "${FILE_PATH%%.*}.png" -rotate -90 "${FILE_PATH%%.*}.png"
            fi
        fi
        ZIP_NAME=$(md5sum ${FILE_PATH%%.*}.png)
        zip -j ${CI_PROJECT_DIR}/builds/${ZIP_NAME}.zip "${FILE_PATH%%.*}.png" "${FILE_PATH%%.*}.json"
    else
        ZIP_NAME=$(md5sum ${FILE_PATH})
        zip -j ${CI_PROJECT_DIR}/builds/${ZIP_NAME}.zip ${FILE_PATH}
    fi
done

for ASSET in ${ALL_ASSETS}
do
    FILE_NAME="$(basename -- $ASSET)"
    if echo ${DIFF_FILES} | grep -q ${FILE_NAME%.*}; then
        continue
    else
        echo ${FILE_NAME} >> ${CI_PROJECT_DIR}/builds/unchanged_assets
    fi
done
