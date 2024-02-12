/*
 *   $Id: exemplo.prg 2256 2012-05-13 01:00:15Z leonardo $
 */

/* NOTE: Source of information:
         http://www.smssolutions.net/tutorials/gsm/receivesmsat/
         http://www.developershome.com/sms/readSmsByAtCommands.asp
         http://www.smssolutions.net/tutorials/gsm/sendsmsat/

Está levando em média 3 segundos para enviar cada mensagem

32000 segundos para 10000 mensagens
534   minutos  para 10000 mensagens
8:09  Horas    para 10000 mensagens

Web-service para consultar a operadora do CELULAR
http://www.telein.com.br/index.php/component/content/article/106

- MONITORA A TABELA: mensagem_detalhe PARA ENVIAR AS MENSAGENS, EM QUANTO O CAMPO: RETORNO
TIVER VAZIO TEM QUE MANDAR A MENSAGEM PARA PEGAR O RETORNO

- CRIAR UM ARQUIVO .INI COM OS PARAMETROS DA CONEXÃO DO POSTGRESQL E DA PORTA COM

- CONECTA UMA VEZ NO MODEM E VAI MANDANDO AS MENSAGENS, DEPOIS NO FINAL DESCONECTA

- FAZER UM MODULO NOVO(exe novo) CONECTAR NA BASE DO SAGI E LISTAR TODOS OS CLIENTE, FORNECEDORES, CREDORES, MOTORISTAS, FUNCIONARIOS PARA ENVIO DE SMS EM LOTE
*/

#pragma /w2
#pragma /es2

#include "hwgui.ch"
#include "hbcompat.ch"
#include "postgres.ch"
#include "hbcom.ch"

#define x_BLUE       16711680
#define x_DARKBLUE   10027008
#define x_WHITE      16777215
#define x_CYAN       16776960
#define x_BLACK             0
#define x_RED             255
#define x_GREEN         32768
#define x_GRAY        8421504
#define x_YELLOW        65535
#define x_GRAY2       8421440
#define CORPADRAO  COLOR_3DLIGHT+3

#define _SMSCTX_xHnd          1
#define _SMSCTX_cPIN          2
#define _SMSCTX_cPrevName     3
#define _SMSCTX_MAX_          3

REQUEST HB_GT_GUI_DEFAULT

STATIC oMainWindow
STATIC lPARAR

FUNCTION MAIN()
LOCAL oServer, hWnd
LOCAL oTrayMenu, oTime
LOCAL oIcon := HIcon():AddResource(1001)

REQUEST HB_CODEPAGE_PTISO
REQUEST HB_LANG_PT

HB_SETCODEPAGE( 'PTISO' )
HB_LANGSELECT( 'PT' )

SET CENTURY ON
SET BELL OFF
SET DATE BRITISH
SET EPOCH TO 2000
SET CONFIRM ON
SET DELETED ON
SET EXACT ON
SET SCOREBOARD OFF
SET WRAP ON
SET EXCLUSIVE OFF
SET AUTOPEN ON
SET OPTIMIZE ON
SET STRICTREAD ON

IF ( hWnd := Hwg_FindWindow( oMainWindow, "Sistema de envio de SMS da Sygecom" ) ) != 0 // verefica se o sistema já esta aberto na estação
   Hwg_SetForegroundWindow( hWnd )
   My_ShowMsg("Esse sistema Já esta aberto, Favor Revisar",5)
   RETURN NIL
ENDIF

oServer := TPQServer():New( 'localhost', 'syg_sms', 'sygecom', '253565', NIL, NIL )
IF oServer:NetErr()
   MY_ShowMsg('Erro ao conectar: ' + valtoprg(oServer:ErrorMsg()))
   RETURN NIL
ELSE
   MY_ShowMsg('Conectou com Sucesso no banco de dados',5)
ENDIF

IF !ATUALIZA_TABELAS(oServer)
   My_ShowMsg('Erro ao criar/alterar tabelas do SMS, favor revisar',5)
   oServer:Destroy()
   RETURN NIL
ENDIF
lPARAR=.F.

   INIT WINDOW oMainWindow MAIN TITLE "Sistema de envio de SMS da Sygecom";
   ICON oIcon ;
   ON EXIT {|| FECHA_CONEXAO(oServer) }

   CONTEXT MENU oTrayMenu
      MENUITEM "Iniciar Sincronização Agora"   ACTION INI_SINCRO(10000)
      SEPARATOR
      MENUITEM "Parar Sincronização"           ACTION INI_SINCRO(0)
      SEPARATOR
      MENUITEM "Fechar"                        ACTION EndWindow()
   ENDMENU

   SET TIMER oTime OF oMainWindow ID 9001 VALUE 10000 ACTION {|| MONITORA_SMS(oServer) }  //300000

   oMainWindow:InitTray( oIcon,,oTrayMenu,"Sistema de envio de SMS da Sygecom")

   ACTIVATE WINDOW oMainWindow NOSHOW
   oTrayMenu:End()

RETURN NIL

********************************
STATIC FUNCTION INI_SINCRO(nHAB)
********************************
oMainWindow:oTime:interval := nHAB
IF nHAB=0
   lPARAR=.T.
   MY_SHOWMSG('Parou a os envio de SMS...',5)
ELSE
   lPARAR=.F.
   MY_SHOWMSG('Vai iniciar os envio de SMS em:'+alltrim(str(nHAB/1000))+' segundos',5)
ENDIF
Return Nil

*************************************
STATIC FUNCTION MONITORA_SMS(oServer)
*************************************
LOCAL nID_MSG:=0, nI, aRET:={}, nID_DETALHE:=0
LOCAL nPORTA:=7, cCEL, cMSG, cRETORNO:=''
Local cSQL:=''
LOCAL smsctx, cPIN, cPort:=''

oMainWindow:oTime:interval := 0 // da um STOP no timer
cSQL:="Select id_detalhe,celular,id_msg,"
cSQL+="(select mensagem from mensagem where mensagem.id_msg=mensagem_detalhe.id_msg limit 1) as texto "
cSQL+="from mensagem_detalhe where retorno='' or retorno is null"

IF !EXECUTA_PGSQL(oServer, cSQL, @aRET)
   IF !lPARAR
      oMainWindow:oTime:interval := 10000
      RETURN NIL
   ENDIF
ENDIF

IF LEN(aRET)<=0
   IF !lPARAR
      oMainWindow:oTime:interval := 10000
      RETURN NIL
   ENDIF
ENDIF

IF Len(aRET)>0
   cPort:=IIF(nPORTA>9,"\\.\COM","COM")+ALLTRIM(STR(nPORTA))
   IF !Empty( smsctx := smsctx_New( cPort ) )  // conecta na porta COM
      SMSCTX_PIN( smsctx, cPIN )   // verefica o numero do PIN
   ELSE
      My_ShowMsg('Não está conectando na porta: ' + STR(nPORTA)+',Favor revisar' ,10)
      //oMainWindow:oTime:interval := 10000
      RETURN NIL
   ENDIF
ENDIF

FOR nI := 1 TO Len(aRET)
   nID_DETALHE:=aRET[nI,1]
   cCEL       :=aRET[nI,2]
   nID_MSG    :=aRET[nI,3]
   cMSG       :=aRET[nI,4]

   IF EMPTY(cCEL)
      EXECUTA_PGSQL(oServer, "update mensagem_detalhe set retorno='Erro: Sem numero de ceular' where id_detalhe="+STR(nID_DETALHE)+' and id_msg='+STR(nID_MSG))
      LOOP
   ELSE
      IF LEN(cCEL) < 10
         EXECUTA_PGSQL(oServer, "update mensagem_detalhe set retorno='Erro: Numero de ceular incompleto' where id_detalhe="+STR(nID_DETALHE)+' and id_msg='+STR(nID_MSG))
         LOOP
      ENDIF
      cCEL:=ALLTRIM(cCEL)
   ENDIF

   IF EMPTY(cMSG)
      EXECUTA_PGSQL(oServer, "update mensagem_detalhe set retorno='Erro: Mensagem vazia' where id_detalhe="+STR(nID_DETALHE)+' and id_msg='+STR(nID_MSG))
      LOOP
   ELSE
      IF LEN(cMSG) > 150
         EXECUTA_PGSQL(oServer, "update mensagem_detalhe set retorno='Erro: Mensagem não pode ultrapassar 150 caracter' where id_detalhe="+STR(nID_DETALHE)+' and id_msg='+STR(nID_MSG))
         LOOP
      ENDIF
      cMSG:=ALLTRIM(cMSG)
   ENDIF

   cRETORNO:=''

   SMSCTX_SEND( smsctx, cCEL, ALLTRIM(cMSG), @cRETORNO )  // envia o SMS

   //SMS_SEND( IIF(nPORTA>9,"\\.\COM","COM")+ALLTRIM(STR(nPORTA)) , cCEL , ALLTRIM(cMSG) , , @cRETORNO )

   hb_comFlush( smsctx, HB_COM_IOFLUSH ) // limpa porta COM de entrada e saida

   EXECUTA_PGSQL(oServer, "update mensagem_detalhe set retorno='"+alltrim(cRETORNO)+ "' where id_detalhe="+STR(nID_DETALHE)+' and id_msg='+STR(nID_MSG))
NEXT

IF Len(aRET)>0
   SMSCTX_CLOSE( smsctx ) // desconecta da porta COM
ENDIF

IF !lPARAR
   oMainWindow:oTime:interval := 10000
ENDIF

RETURN NIL
/*
******************************************************************
STATIC FUNCTION SMS_SEND( cPort, cPhoneNo, cText, cPIN, cRETORNO )
******************************************************************
LOCAL smsctx

IF !Empty( smsctx := smsctx_New( cPort ) )
   smsctx_PIN( smsctx, cPIN )

   smsctx_Send( smsctx, cPhoneNo, cText, @cRETORNO )

   smsctx_Close( smsctx )
ELSE
   cRETORNO:=cRETORNO+HB_OsNewLine() +'Erro: Não conectou a PORTA: '+ cPort
ENDIF

RETURN NIL
*/

STATIC FUNCTION SMSCTX_NEW( xPort )
   LOCAL smsctx[ _SMSCTX_MAX_ ]

   IF HB_ISNUMERIC( xPort )
      smsctx[ _SMSCTX_xHnd ] := xPort
      smsctx[ _SMSCTX_cPrevName ] := NIL
   ELSEIF HB_ISSTRING( xPort )
      smsctx[ _SMSCTX_xHnd ] := 1
      smsctx[ _SMSCTX_cPrevName ] := hb_comGetDevice( smsctx[ _SMSCTX_xHnd ] )
      hb_comSetDevice( smsctx[ _SMSCTX_xHnd ], xPort )
   ELSE
      smsctx[ _SMSCTX_xHnd ] := NIL
   ENDIF

   IF smsctx[ _SMSCTX_xHnd ] != NIL
      IF hb_comOpen( smsctx[ _SMSCTX_xHnd ] )
         IF hb_comInit( smsctx[ _SMSCTX_xHnd ], 9600, "N", 8, 1 )
            RETURN smsctx
         ELSE
            hb_comClose( smsctx[ _SMSCTX_xHnd ] )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

STATIC FUNCTION smsctx_Close( smsctx )

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      RETURN .F.
   ENDIF

   IF ! hb_comClose( smsctx[ _SMSCTX_xHnd ] )
      RETURN .F.
   ENDIF

   /* Restore com port name */
   IF smsctx[ _SMSCTX_cPrevName ] != NIL
      hb_comSetDevice( smsctx[ _SMSCTX_xHnd ], smsctx[ _SMSCTX_cPrevName ] )
   ENDIF

   RETURN .T.

STATIC FUNCTION SMSCTX_SEND( smsctx, cPhoneNo, cText, cRETORNO )
   LOCAL tmp

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      cRETORNO:=cRETORNO+HB_OsNewLine() +"Erro ao enviar parametros"
      RETURN -1
   ENDIF

   IF ! Empty( smsctx[ _SMSCTX_cPIN ] ) // SE TIVER UM PIN PREENCHIDO
      hb_comSend( smsctx[ _SMSCTX_xHnd ], 'AT+CPIN="' + smsctx[ _SMSCTX_cPIN ] + '"' + Chr( 13 ) )
      tmp:=StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )
      IF !( right(tmp,2) == "OK" )
         cRETORNO:=cRETORNO+HB_OsNewLine() +"Erro: PIN Invalido: "+valtoprg(tmp)
         RETURN NIL
      ENDIF
   ENDIF

   hb_comSend( smsctx[ _SMSCTX_xHnd ], "AT+CMGF=1" + Chr( 13 ) )
   tmp := StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )

   IF right(tmp,2) = "OK" // SE O MODEM É COMPATIVEL COM MODO TEXTO
      hb_comSend( smsctx[ _SMSCTX_xHnd ], 'AT+CMGS="' + cPhoneNo + '"' + Chr( 13 ) )
      tmp:=StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )

      IF Right(tmp,1) = ">" // SE CONSEGUE ENVIAR PARA O NUMERO A MENSAGEM
         hb_comSend( smsctx[ _SMSCTX_xHnd ], StrTran( cText, Chr( 13 ) ) + Chr( 26 ) )
         tmp := port_rece( smsctx[ _SMSCTX_xHnd ] )

         // O RETORNO GERALMENTE É: CMGS: + O ID DE IDENTIFICAÇÃO DA MENSAGEM
         //CMS ERROR: 500  // DEU ERRO COM NUMERO 1111-1111
         //REG: 1, C44B    // ENVIO COM SUCESSO
         //+CMGS:          // ENVIO COM SUCESSO

         //IF Left( tmp, Len( "+CMGS: " ) ) == "+CMGS: "
         IF "+CMGS:"$tmp
            cRETORNO:=cRETORNO+HB_OsNewLine() +"Enviado com Sucesso"
            RETURN NIL
         ELSE
            cRETORNO:=cRETORNO+HB_OsNewLine() +"Erro:"+valtoprg(tmp)
            RETURN NIL
         ENDIF
      ELSE
         cRETORNO:=cRETORNO+HB_OsNewLine() +"Erro com numero de Celular:"+valtoprg(tmp)
         RETURN NIL
      ENDIF
   ELSE
      cRETORNO:=cRETORNO+HB_OsNewLine() +"Erro: Modem Incompativel ou Porta errada"
      RETURN NIL
   ENDIF
RETURN NIL

FUNCTION SMSCTX_PIN( smsctx, cPIN )
   LOCAL cOldValue

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      RETURN NIL
   ENDIF

   cOldValue := smsctx[ _SMSCTX_cPIN ]
   IF cPIN == NIL .OR. ( HB_ISSTRING( cPIN ) .AND. Len( cPIN ) == 4 )
      smsctx[ _SMSCTX_cPIN ] := cPIN
   ENDIF

   RETURN cOldValue

STATIC FUNCTION StripCRLF( cString )
   RETURN StrTran( alltrim(cString), Chr( 13 ) + Chr( 10 ) )

************************************
STATIC FUNCTION PORT_RECE( h, n, t )
************************************
LOCAL cString:=''
Local nLOOP  := 0
Local nESPERA:= 0
Local nBytesRecv:=0
LOCAL nINICIO:=0, nFIM:=0

IF ! HB_ISNUMERIC( n )
   n := 64
ENDIF

IF ! HB_ISNUMERIC( t )
   t := 5
ENDIF

cString := Space( n )
Millisec(100)
nINICIO:=TimeToSec(TIME())

DO WHILE .T.
   nLOOP=nLOOP+1
   nESPERA=nESPERA+1

   nBytesRecv:=hb_comRecv( h, @cString,, t )

   IF nBytesRecv >= n
      EXIT
   ENDIF

   IF !EMPTY(ALLTRIM(cString))
      EXIT
   ENDIF

   IF nESPERA = 1000
      Millisec(100)
      nESPERA = 0
   ENDIF

   IF nLOOP > 30000
      cString := "SEM_SINAL"
      EXIT
   ENDIF
   nFIM:=TimeToSec(TIME())

   IF nFim-nInicio>=20 //20 SEGUNDOS ELE CAI FORA
      EXIT
   ENDIF
ENDDO

RETURN cString

*****************************************
STATIC FUNCTION ATUALIZA_TABELAS(oServer)
*****************************************
Local aStruct:={}, nI, nI2, lRET:=.T., aTABELAS:={}
Local aRET:={}

AADD(aTABELAS,'mensagem')
AADD(aTABELAS,'mensagem_detalhe')
AADD(aTABELAS,'sequencia')
//AADD(aTABELAS,'cliente')

FOR nI := 1 TO LEN(aTABELAS)
   aStruct:={}
   aStruct:=ESTRUTURA_TABELAS(aTABELAS[nI])
   IF !oServer:TableExists(aTABELAS[nI])
      IF !oServer:CreateTable( aTABELAS[nI], aStruct )
         IF oServer:NetErr()
            MY_ShowMsg('Erro ao criar tabelas: '+aTABELAS[nI]+ HB_OsNewLine() +;
                    oServer:ErrorMsg(),15)
         ENDIF
         lRET:=.F.
         EXIT
      ENDIF
   ENDIF

   IF lRET
      FOR nI2 := 1 TO LEN(aStruct)
         IF aStruct[nI2,6]
            IF !oServer:IndexExists( aTABELAS[nI] , aTABELAS[nI]+'_'+ALLTRIM(STR(nI2)) )
               IF !EXECUTA_PGSQL(oServer,'CREATE INDEX '+aTABELAS[nI]+'_'+ALLTRIM(STR(nI2))+ ' ON ' +aTABELAS[nI]+ ' USING btree ('+aStruct[nI2,1]+')' ) // exeuta uma query
                  MY_ShowMsg('Erro ao criar indices da tabela: '+aTABELAS[nI]+ HB_OsNewLine() +;
                          oServer:ErrorMsg(),15)
                  lRET:=.F.
                  EXIT
               ENDIF
            ENDIF
         ENDIF
      NEXT
   ENDIF
NEXT

IF lRET
   IF !EXECUTA_PGSQL(oServer,"select id_seq from sequencia where tipo='SMS'", @aRET ) // exeuta uma query
      MY_ShowMsg('Erro ao abrir a tabela SEQUENCIA'+ HB_OsNewLine() +;
              oServer:ErrorMsg(),15)
      lRET:=.F.
   ELSE
      IF LEN(aRET)=0 // AINDA NÃO FOI CRIADO UM PRIMEIRO REGISTRO
         IF !EXECUTA_PGSQL(oServer, "INSERT INTO sequencia (id_seq,tipo) VALUES(1,'SMS')")
            MY_ShowMsg('Erro ao criar registro na tabela SEQUENCIA'+ HB_OsNewLine() +;
                    oServer:ErrorMsg(),15)
            lRET:=.F.
         ENDIF
      ENDIF
   ENDIF
ENDIF

RETURN(lRET)

******************************************
STATIC FUNCTION ESTRUTURA_TABELAS(cTABELA)
******************************************
*AADD(aStruct,{NOME DO CAMPO,
*              TIPO DE CAMPO,
*              TAMANHO DO CAMPO,
*              DECIMAL DO CAMPO,
*              COMENTARIO DO CAMPO,
*              SE DEVE CRIAR UM INDICE OU NÃO DO CAMPO })

LOCAL aStruct:={}

IF cTABELA='mensagem'
   AADD(aStruct,{'ID_MSG'    ,'N', 10,0,'ID DA MENSAGEM', .T. })
   AADD(aStruct,{'ID_CLIENTE','N', 10,0,'CLIENTE QUE ENVIO MENSAGEM',.T.})
   AADD(aStruct,{'MENSAGEM'  ,'M', 10,0,'RETORNO DO ENVIO DA MENSAGEM',.F. })
   AADD(aStruct,{'DATA'      ,'D', 08,0,'DATA DO ENVIO',.F. })
   AADD(aStruct,{'HORA'      ,'C', 10,0,'HORA DO ENVIO',.F. })
ELSEIF cTABELA='mensagem_detalhe'
   AADD(aStruct,{'ID_DETALHE','N', 10,0,'ID DO DETALHAMENTO DA MENSAGEM',.T. })
   AADD(aStruct,{'ID_MSG'    ,'N', 10,0,'ID DA MENSAGEM',.T. })
   AADD(aStruct,{'CELULAR'   ,'C', 15,0,'CELULAR PARA QUAL VAI A MENSAGEM',.F. })
   AADD(aStruct,{'RETORNO'   ,'M', 10,0,'RETORNO DO ENVIO DA MENSAGEM',.F. })
ELSEIF cTABELA='sequencia'
   AADD(aStruct,{'ID_SEQ'    ,'N', 10,0,'ID DA SEQUENCIA',.T. })
   AADD(aStruct,{'TIPO'      ,'C', 25,0,'TIPO DE SEQUENCIA',.F. })
ENDIF

RETURN(aStruct)

**************************************
STATIC FUNCTION FECHA_CONEXAO(oServer)
**************************************
oServer:Destroy()
MY_ShowMsg('Desconectou do Banco de dados',5)
RETURN(.T.)

