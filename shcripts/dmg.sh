#!/bin/bash

dmg:make(){
    # Var mapping
    volumeTitle=$1
    dmgFileName=$2

    appName=$3
    appBasePath=$4
    cd "$appBasePath"
    appSource=${appBasePath}/${appName}.app

    backgroundName=$5
    backgroundBasePath=$6
    backgroundSource=${backgroundBasePath}/${backgroundName}

    # Clean the shit
    if [[ -e "posh.temp.dmg" ]]; then
        rm posh.temp.dmg
    fi

    if [[ -e "${dmgFileName}.dmg" ]]; then
        rm "${dmgFileName}.dmg"
    fi

    # Creation of tmp dmg
    hdiutil create -srcfolder "${appSource}" -volname "${volumeTitle}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m posh.temp.dmg
    device=$(hdiutil attach -readwrite -noverify -noautoopen "posh.temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')
    sleep 5

    # Put image in
    mkdir "/Volumes/${volumeTitle}/.background/"; cp "${backgroundSource}" "/Volumes/${volumeTitle}/.background/"

    # Order applescript to do the deed
    echo '
        tell application "Finder"
            tell disk "'${volumeTitle}'"
                    open
                        tell container window
                            set current view to icon view
                            set toolbar visible to false
                            set statusbar visible to false
                            set the bounds to {100, 100, 800, 500}
                        end tell

                        set theViewOptions to the icon view options of container window
                        tell theViewOptions
                            set arrangement to not arranged
                            set icon size to 158
                        end tell

                        set background picture of theViewOptions to file ".background:'${backgroundName}'"

                        set position of item "'${appName}'" of container window to {190, 245}

                        make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
                        set position of item "Applications" of container window to {505, 237}

                    close
                    open
                        update without registering applications
                        delay 5

                        # tell container window
                        #     set current view to icon view
                        #     set toolbar visible to false
                        #     set statusbar visible to false
                        #     set the bounds to {100, 100, 800, 500}
                        # end tell

                        # set position of item "'${appName}'" of container window to {225, 270}
                        # set position of item "Applications" of container window to {540, 260}

                        # update without registering applications
                        # delay 1
                # eject
            end tell
        end tell
    ' | osascript

    # Chmod the shit, convert, cleanup
    chmod -Rf go-w "/Volumes/${volumeTitle}"
    sync
    sync
    hdiutil detach ${device}
    hdiutil convert "posh.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${dmgFileName}"

    rm posh.temp.dmg
    cd - > /dev/null
}

