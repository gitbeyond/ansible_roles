
url='https://jms-ops.biyao.com/api/v1/assets/assets/37ae7a6d-14bb-4231-a8ab-59cae210be8d/'
#method=GET
method=PATCH
#headers="-H 'Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476' -H 'Content-Type: application/json' -H 'X-JMS-ORG: 00000000-0000-0000-0000-000000000002'"
headers='-H "Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476" -H "Content-Type: application/json" -H "X-JMS-ORG: 00000000-0000-0000-0000-000000000002"'
#headers='-H \"Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476\" -H \"Content-Type: application/json\" -H \"X-JMS-ORG: 00000000-0000-0000-0000-000000000002\"'
#headers='-H \'Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476\' -H \'Content-Type: application/json\' -H \'X-JMS-ORG: 00000000-0000-0000-0000-000000000002\''
#headers="-H \'Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476\' -H \'Content-Type: application/json\' -H \'X-JMS-ORG: 00000000-0000-0000-0000-000000000002\'"
#headers="-H \'Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476\' -H \'Content-Type: application/json\' -H \'X-JMS-ORG: 00000000-0000-0000-0000-000000000002\'"
#headers="-H \"Authorization: Token 6d83611afe1aa8823a76f421fc878a02d1035476\" -H \"Content-Type: application/json\" -H \"X-JMS-ORG: 00000000-0000-0000-0000-000000000002\""
body='
{
                "admin_user": "0b79cebc-8b00-46f8-887b-767668719703",
                "hostname": "k8s-node-56-161",
                "ip": "10.6.56.161",
                "platform": "Linux"
            }
'

#cmd_str='''curl -i -X ${method} -d "${body}" ${headers} ${url}'''
cmd_str='''curl -i -X ${method} -d "${body}"'''
cmd_str="${cmd_str} ${headers} ${url}"
eval ${cmd_str}
