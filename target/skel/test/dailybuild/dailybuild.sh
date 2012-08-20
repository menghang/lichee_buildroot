#!bin/sh

CUR_DIR=`pwd`
echo -e "\n########## Start daily build! ##########\n"

echo -e "\nSTORAGE TESTING ------>>"
cd ${CUR_DIR}/storage/ && ./storage.sh

echo -e "\nMEDIA TESTING ------>>"
cd ${CUR_DIR}/media/ && ./media.sh

echo -e "\nBASIC TESTING ------>>"
cd ${CUR_DIR}/basic/ && ./basic.sh

echo -e "\nSYSTEM TESTING ------>>"
cd ${CUR_DIR}/system/ && ./system.sh

echo -e "\n########## End daily build! ##########\n"
exit 0
