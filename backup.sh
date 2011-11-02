#!/bin/bash

BACKUP_FOLDER=~/backup
BACKUP_LIST=$BACKUP_FOLDER/list

function list_backup {
    count=0
    echo "ID Source File/Folder Location"
    echo "--------------------------------"
    cat $BACKUP_LIST | while read LINE
    do
           let count++
           source_folder=${LINE%%|*}
           rest=${LINE#*|}
           source_file=${rest%%|*}
           echo $count $source_folder/$source_file
    done
}

case $1 in
    init)
        if [ -d $BACKUP_FOLDER ]; then
            touch $BACKUP_FOLDER/list
            echo "Backup already initialized."
        else 
            mkdir $BACKUP_FOLDER
            touch $BACKUP_FOLDER/list
            echo "Backup folder initialized"
        fi
        ;;
    backup)
        if [ $2 ]; then
            i=0
            for var in "$@"
            do
                let i++
                if [ $i = 1 ]; then
                    continue
                fi

                count=0
                name=$var

                flag="FALSE"
                flag=$(cat $BACKUP_LIST | while read LINE
                do
                    let count++
                    source_folder=${LINE%%|*}
                    rest=${LINE#*|}
                    source_file=${rest%%|*}
                    if [[ "$source_folder" == "$PWD" && "$source_file" == "$var" ]]; then
                        flag="TRUE"
                        echo $flag
                        break
                    fi
                done)

                if [ "$flag" == "TRUE" ]; then
                    cp -u -r -i $var $BACKUP_FOLDER/$name
                    echo "Backup updated for file $var"
                else
                    while [ -e $BACKUP_FOLDER/$name ]; do
                        let count++
                        name=$var.$count
                    done
                    back_folder=$BACKUP_FOLDER/$var
                    parent_folder=$PWD/$var
                    mkdir -p ${back_folder%\/*}
                    cp -u -r -i $var $BACKUP_FOLDER/$name
                    echo ${parent_folder%\/*}\|${var##*/}\|$name >> $BACKUP_LIST
                    echo "Backup created for file $var"
                fi
            done

        else
            echo "no file specified"
        fi
        ;;
    restore)
        if [ $2 ]; then
            if [[ $2 == +([0-9]) ]]
            then
               line=$(sed -n "$2 p" $BACKUP_LIST)
               source_folder=${line%%|*};
               rest=${line#*|}
               source_file=${rest%%|*};
               backup_file=${rest#*|}
               cp -r -i $BACKUP_FOLDER/$backup_file $source_folder/$source_file
               echo "Data restored to $source_folder/$source_file"
            else
               list_backup
               echo "--------------------------------"
               echo "Please give the backup id/number instead of \"$2\""
            fi
        else
            list_backup
        fi
        ;;
    delete)
        if [ $2 ]; then
            if [[ $2 == +([0-9]) ]]
            then
               line=$(sed -n "$2 p" $BACKUP_LIST)
               source_folder=${line%%|*};
               rest=${line#*|}
               source_file=${rest%%|*};
               backup_file=${rest#*|}
               rm -rf $BACKUP_FOLDER/$backup_file
               sed "$2 d" $BACKUP_LIST > $BACKUP_FOLDER/.temp
               mv $BACKUP_FOLDER/.temp $BACKUP_LIST
               echo "Backup file '$source_file' deleted."
            else
               list_backup
               echo "--------------------------------"
               echo "Please give the backup id/number instead of \"$2\""
            fi
        else
            list_backup
        fi
        ;;
    empty)
        echo "Are you sure want to trash all backups ? (y/N)"
        read choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            rm -rf $BACKUP_FOLDER
            echo "All backup data deleted"
        fi
        ;;
    *)
        echo "Backup tool."
        echo "--------------------------------"
        echo "Parameters"
        echo "init                  -   initialize backup"
        echo "backup [file name/folder name/wildcard] - Backup file(s) or folder(s)"
        echo "restore [backup id]   -   Restore backup"
        echo "delete [backup id]    -   Delete a backup"
        echo "empty                 -   Delete/distroy all backups"
        
esac

