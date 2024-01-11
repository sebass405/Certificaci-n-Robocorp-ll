*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium  auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Images


*** Variables ***
${TMP_DIR}             ${OUTPUT_DIR}${/}DATOS
${TMP_SCREENSHOT_DIR}  ${TMP_DIR}${/}SCREENSHOTS_FOR_ORDER
${TMP_RECEIPTS_DIR}    ${TMP_DIR}${/}PDF_FOR_ORDER


*** Tasks ***
Order robots from RobotSpareBin Industries Inc 
    Open the robot order website
    ${orders}=  Get Orders
    Orders  ${orders}
    Create ZIP package from PDF files
    [Teardown]    Close Browsers

*** Keywords ***
Open the robot order website
#Abrimos la pagina
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Fill the form
#Se llena el formulario
    [Arguments]  ${order}
    Log   ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //input[@class='form-control' and @type='number']    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Download the Orders file
#Descarga el archivo .cvsv
    Download    https://robotsparebinindustries.com/orders.csv  overwrite=True

Get Orders
#Se llena una lista con el archivo .csv
    Download the Orders file
    ${orders}=    Read table from CSV    orders.csv
    Close Workbook
    RETURN    ${orders} 


Close the annoying modal
#Se cierra el modal molesto
    Click Button When Visible    //button[@class='btn btn-dark']
        
Preview Robot
#Click en ver robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit Order
#Click en Orden y verifica que no haya salga el error
    Click Button    id:order
    Wait Until Element Is Not Visible    id:order  timeout=500ms

Store the order receipt as a PDF file
#Se guarda el pedido como un pdf
    [Arguments]  ${order_nro}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_file}=  Set Variable  ${TMP_RECEIPTS_DIR}${/}order_receipt_${order_nro}.pdf
    Html To Pdf    ${order_receipt_html}    ${pdf_file}
    Wait Until Created  ${pdf_file}
    RETURN  ${pdf_file}

Take a screenshot of the robot
#Se hace un screenshot a la imagen del Robot
    [Arguments]  ${order_nro}
    ${screenshot}=  Set Variable  ${TMP_SCREENSHOT_DIR}${/}order_robot_${order_nro}.png
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot  id:robot-preview-image  filename=${screenshot} 
    Wait Until Created  ${screenshot}
    RETURN  ${screenshot}

Embed the robot screenshot to the receipt PDF file
#Incrustamos el screenshot en un pdf
    [Arguments]  ${screenshot}  ${pdf}
    ${tmp_list}=  Create List  ${screenshot}
    Add Files To Pdf    files=${tmp_list}   target_document=${pdf}  append=True

Order Another Robot
#Se le da click a pedir otro robot
    Click Button    id:order-another
Orders
#Se hace el ciclo para cada orden
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview Robot
        Wait Until Keyword Succeeds  5x  200ms  Submit Order
        ${pdf}=  Store the order receipt as a PDF file  ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order Another Robot 
    END


Create ZIP package from PDF files
#Se crea un archivo .zip donde se almacenan cada pdf de las ordenes
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDF_COMPLETOS.zip
    Archive Folder With Zip
    ...    ${TMP_RECEIPTS_DIR}
    ...    ${zip_file_name}

Close Browsers
#Cerramos la pagina
    Close All Browsers
    

