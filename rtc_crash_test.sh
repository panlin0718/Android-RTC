#!/bin/bash


function getDevices(){
        devices=`adb devices | grep 'device$' | awk '{print $1}' | tr '\n' ' '`;

        printf "All devices list:%s\n" "${devices[@]}";
        devices=(${devices});
        printf "Devices numbers:%d\n " ${#devices[@]};
}
#Debug mode setting
if [[ $1 == '' ]];then
    echo "**************************Test Mode******************************"
    echo "                        Test Mode Open                           "
    echo "                        Test Mode Open                           "
    echo "**************************Test Mode******************************"
fi

#输入流量统计时间,单位为秒,默认为60秒
if [[ $2 == '' ]];then
    RUN_TIME=60
    SDK_START_TIME=30
else
    RUN_TIME=$2
    SDK_START_TIME=60
fi
#默认为All connect devices,也可以指定某几个device sn,如'SJE5T17707000515 db9fcded'
if [[ $3 == '' ]];then
    getDevices
    DEVICES=${devices[@]}
else
    DEVICES_SPECIAL=$3
    DEVICES=(${DEVICES_SPECIAL})
fi
#需要运行项目的根目录,通过该目录找到apk打包入口
if [[ $4 == '' ]];then
    PROJECT_PATH=$(pwd)
else
    PROJECT_PATH=$4
fi
#APP运行时log保存的路径
if [[ $5 == '' ]];then
    LOCAL_STORAGE_PATH=$(pwd)
else
    LOCAL_STORAGE_PATH=$5
fi
#APP的package name,方便关闭当前的APP
if [[ $6 == '' ]];then
    PACKAGE_NAME='com.qiniu.droid.rtc.demo'
else
    PACKAGE_NAME=$6
fi
#APK的路径
if [[ $7 == '' ]];then
    APK_PATH='/apps/com.qiniu.droid.rtc.demo.apk'
    APK_FULL_PATH="$PROJECT_PATH""$APK_PATH"
    echo "$APK_FULL_PATH PANLIN"
else
    APK_PATH=$7
    APK_FULL_PATH="$PROJECT_PATH""$APK_PATH"
    echo "$APK_FULL_PATH PANLIN"
fi
#APP的Activity,方便自动化打开指定的Activity
if [[ $8 == '' ]];then
    APP_ACTIVITY='.activity.WelcomeActivity'
else
    APP_ACTIVITY=$8
fi
#Open the user operation mode,
# 'USER' is opened status
# '' is disable status
if [[ $9 == '' ]];then
    USER_OPERATION=''
else
    USER_OPERATION=$9
fi

echo "Current run time setting = "${RUN_TIME}
echo "Current devices = "${DEVICES}
echo "Current project path = "${PROJECT_PATH}
echo "Current log root path = "${LOCAL_STORAGE_PATH}
echo "Current package name = "${PACKAGE_NAME}
echo "Current apk path = "${APK_PATH}
echo "Current full apk path = "${APK_FULL_PATH}
SHELL_ROOT_PATH=$(cd `dirname $0`; pwd)
echo "Current python script root path = "${SHELL_ROOT_PATH}
echo "Current user operation status = "${USER_OPERATION}


function getUTCSecond(){
        utcTime=`date +'%s'`;
        #printf "%d\n" $utcTime;
}
function printDate(){
        dateStr=`date +'%Y%m%d-%H%M%S'`;
        #printf "%s %s\n" $dateStr;
}

function getActiveActivity(){
    ACTIVITIES=$(adb -s ${DEVICE_ID} shell dumpsys activity | grep -i run | grep '#')
    ACTIVITY=$(adb -s ${DEVICE_ID} shell dumpsys activity | grep -i run | grep '#'| head -n 1)
    echo $ACTIVITY" "${DEVICE_ID}
}



function startApp(){
    echo ${DEVICE_ID}" APK start install"
    echo ${DEVICE_ID}" Back to home and stop $PACKAGE_NAME app"
    adb -s ${DEVICE_ID} shell input keyevent 4
    adb -s ${DEVICE_ID} shell am force-stop ${PACKAGE_NAME}
   
    adb -s ${DEVICE_ID} shell pm uninstall $PACKAGE_NAME
    adb -s ${DEVICE_ID} shell rm -rf /sdcard/qxsdk/*debug_java_logger*
    adb -s ${DEVICE_ID} shell rm -rf /sdcard/qxsdk/*so_log*

    adb -s ${DEVICE_ID} logcat -c
    adb -s ${DEVICE_ID} logcat -v time > $LOCAL_STORAGE_PATH'/logcat.txt' &
    echo "$!" >> $LOCAL_STORAGE_PATH'/pid'
    adb -s ${DEVICE_ID} push $APK_FULL_PATH "/data/local/tmp/$PACKAGE_NAME"
    adb -s ${DEVICE_ID} shell pm install -r "/data/local/tmp/$PACKAGE_NAME"
   
    # adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.ACCESS_FINE_LOCATION"
    # adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.ACCESS_COARSE_LOCATION"
    adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.READ_PHONE_STATE"
    adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.WRITE_EXTERNAL_STORAGE"
    # adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.MOUNT_UNMOUNT_FILESYSTEMS"
    adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.READ_EXTERNAL_STORAGE"

    #获取相机和录音权限
    adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.CAMERA"
    adb -s ${DEVICE_ID} shell pm grant $PACKAGE_NAME "android.permission.RECORD_AUDIO"
 
    sleep 3
    adb -s ${DEVICE_ID} shell am start -n "$PACKAGE_NAME/$APP_ACTIVITY"
     
}


function startRTC(){

    echo ${DEVICE_ID}" Setup configuration interface"
    
    adb shell input text "${DEVICE_ID}"
    adb shell input tap 700 800
    sleep 2
    echo ${DEVICE_ID}" Enter the meeting room"
    adb shell input tap 700 1200
    adb shell input tap 300 1900
    adb shell input tap 700 1900    
     
}


function enterRoom(){

    echo ${DEVICE_ID}" Enter the meeting room"
    adb shell input tap 700 1200
    #mute 操作
    adb shell input tap 300 1900 
    adb shell input tap 700 1900    
     
}

function crashCheck(){
    #执行长时间运行操作
    printf "Get init time. Device=%s,Date=%s,initTime=%d\n" ${DEVICE_ID} "$dateStr" ${initTime};
    echo "Wait "${DEVICE_ID}" "$RUN_TIME" seconds for long time stability testing:"
    STATUS=''
    CRASH_COUNT=0
    #开始连麦
    startRTC
    #获取连麦当前界面的 activity 名
    echo "current RTC_Activity is："
    getActiveActivity
    RTC_ACTIVITY=${ACTIVITY};


    #执行长时间运行连麦，并检测crash
    while : ;do
          getUTCSecond
          printDate
          currentTime=${utcTime};
          countTime=$[$initTime+$RUN_TIME]
          sdkTime=$[$initTime+$SDK_START_TIME]
          DEVICE_STATUS=$(adb -s ${DEVICE_ID} get-state)
          sleep 2
          #获取实时界面的 activity 名
          echo "current Activity is："
          getActiveActivity
        
          if [[ ! $ACTIVITY =~ $RTC_ACTIVITY ]];then
                ((CRASH_COUNT+=1))

                #重新打开APP，并进入连麦房间
                adb -s ${DEVICE_ID} shell am start -n "$PACKAGE_NAME/$APP_ACTIVITY"
                enterRoom

                echo "Current crash count = "$CRASH_COUNT
                if [[ $CRASH_COUNT -gt 40 ]];then
                    echo  $PACKAGE_NAME" has not top of stack , maybe the package have been exited"
                    echo "Current activity stacks: $ACTIVITIES"
   
                fi
          fi
          if [ ${currentTime} -gt ${sdkTime} ];then
               printDate
               echo "Current SDK = "$STATUS
               printf "Start send broadcast.Device=%s,Date=%s,UTCTime=%d\n" ${DEVICE_ID} "$dateStr" ${currentTime};
               if [[ $STATUS = '' ]];then
                    # startSDK
                    STATUS='Started'
               fi
          fi
          if [ ${currentTime} -gt ${countTime} ];then
               printDate
               printf "Wait time arrived and exit wait.Device=%s,Date=%s,UTCTime=%d\n" ${DEVICE_ID} "$dateStr" ${currentTime};
               break;
          fi
          sleep 20
    done

    echo "crash 次数为" ${CRASH_COUNT}

    #关闭APP
    adb -s ${DEVICE_ID} shell am force-stop ${PACKAGE_NAME}
}

printDate
getUTCSecond
initTime=${utcTime};
initDateTime=${dateStr}

#并发操作，shell中会创建多个进程
for device in ${DEVICES[*]};do
    {
        DEVICE_ID=$device
        echo "Current DEVICE_ID thread = "$DEVICE_ID
    
        startApp
        sleep 5
        crashCheck

        
    } &
done

wait
exit 0

