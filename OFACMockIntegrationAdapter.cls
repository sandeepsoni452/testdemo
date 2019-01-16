/**
*@author
*@description class implements AbstractMockAdapter and serves as as adapter for OFAC check.
*/
public class OFACMockIntegrationAdapter extends AbstractMockAdapter{
/*
* implementaion for AbstractMockAdapter.
*/
	private String mockResponseStatus = null ;
 	private String adpterName = null ;
    
    public override HttpRequestObject createRequest(Map<String, Object> OFACVerificationRequest, IntegrationConfigurationDTO IntegrationConfiguration)
   {
       System.debug('Inside Bank verification of OFAC');
        System.debug(LoggingLevel.eRROR,'Integration Configu'+OFACVerificationRequest+'=>'+IntegrationConfiguration);
        
       if(OFACVerificationRequest == NULL){

            throw new IntegrationException('Request Parameter Map should not be empty');  

        }
		system.debug('inside createRequest');
       //Set Endpoint,timeout, header & method
       HttpRequestObject httpReq = new HttpRequestObject();
       httpReq.endpoint = 'callout:'+ integrationConfiguration.apiNamedCredential;
        httpReq.timeout = 60000 ;
        httpReq.method = 'GET';
       
       //Header
        Map<String,String> headerMap = new Map<String,String>();
        headerMap.put('Content-type','text/xml;charset=utf-8');
        httpReq.headerMap = headerMap;
       
       
       //Create third-party specific request body.
        String reqBody =  getRequestBody(OFACVerificationRequest);
        httpReq.body = reqBody;
        adpterName = integrationConfiguration.name;
        System.debug(' request mockResponseStatus===>'+mockResponseStatus); 
        return httpReq;
   }
    
private String getRequestBody(Map<String,Object> OFACVerificationRequestparameters) {
        System.debug(LoggingLevel.ERROR,' Generating Request From OFACChekRequest: '+OFACVerificationRequestparameters);
    try {
     String requestXml = null;
        List<Map<String,Object>> borrowerRecords = (List<Map<String,Object>>)OFACVerificationRequestparameters.get(OFACMockAdapterConstants.BORROWER);
		requestXml = '<?xml version="1.0" encoding="UTF-8">'
		 +'<BusinessOFACCheck xmlns="http://webservices.ofac.com/">'
            +'<FirstName>'+String.valueOf(borrowerRecords.get(0).get(OFACMockAdapterConstants.BORROWER_FIRST_NAME))+'</FirstName>'
            +'<LastName>'+String.valueOf(borrowerRecords.get(0).get(OFACMockAdapterConstants.BORROWER_LAST_NAME))+'</LastName>'
            +'<Street>'+String.valueOf(borrowerRecords.get(0).get(OFACMockAdapterConstants.BORROWER_STREET))+'</Street>'
           +'<DOB>'+String.valueOf(borrowerRecords.get(0).get(OFACMockAdapterConstants.BORROWER_BIRTH_DATE))+'</DOB>' 
            +'<BusinessOFACCheck> ';
		system.debug('final request xml is '+requestXml);
               mockResponseStatus = (getMockResponseStatus(String.valueOf(borrowerRecords.get(0).get(OFACMockAdapterConstants.BORROWER_LAST_NAME))))
            ? OFACMockAdapterConstants.RESPONSE_SUCCESS_STATUS : OFACMockAdapterConstants.RESPONSE_FAILURE_STATUS;

        return requestXml;
        
 } catch (Exception ex) {
            system.debug(ex.getMessage());
              system.debug(ex.getcause());
                          system.debug(ex.getLineNumber());
                                      system.debug(ex.getStackTraceString());
                                                  system.debug(ex.getTypeName());
            return null;
        }
 }
    
 private Boolean getMockResponseStatus(String param){
       List<IntegrationMockResponse__c> OFACMockResponsetemp = [ SELECT Success_last_name__c  FROM IntegrationMockResponse__c 

                                                            WHERE ReponseStatus__c ='Success'

                                                            AND AdapterName__c =: OFACMockAdapterConstants.ADAPTER_NAME                                                            

                                                           ];
     for(IntegrationMockResponse__c c :OFACMockResponsetemp)
     {
     if(c.Success_last_name__c==param){
        return true;
     }
   
    }
 return false;
 }
 
    /*
* MEthod parses response received from OFAC .
*/ 
public override  IntegrationResponseObject parseResponse(HttpResponse response) {

        OFACMockAdapterResponse responseObj ;
		System.debug('response.status===>'+response.getStatus()+'~'+response.getStatusCode());        
		System.debug(' resp mockResponseStatus===>'+mockResponseStatus);        
        List<IntegrationMockResponse__c> OFACMockResponse = [ SELECT Success_last_name__c,Possible_Matches__c,Comments__c, Verification_Status__c FROM IntegrationMockResponse__c 

                                                            WHERE ReponseStatus__c =: mockResponseStatus

                                                            AND AdapterName__c =: OFACMockAdapterConstants.ADAPTER_NAME                                                            

                                                           ];

        

        System.debug('OFACMockResponse.size()='+OFACMockResponse.size());               
        JSONGenerator genJson = JSON.createGenerator(true);

        genJson.writeStartObject();
        if(OFACMockResponse.get(0).Possible_Matches__c!=null){
        genJson.writeStringField('Possible_Matches', OFACMockResponse.get(0).Possible_Matches__c);        
    }
    else
        genJson.writeNullField('Possible_Matches');
    if(OFACMockResponse.get(0).Comments__c!=null){
        genJson.writeObjectField('Comments',OFACMockResponse.get(0).Comments__c);        
    }
    else
        genJson.writeNullField('Comments');
    genJson.writeEndObject();

        String responseJson = genJson.getAsString();
        System.debug('responseJson=='+responseJson);
        responseObj =  (OFACMockAdapterResponse)JSON.deserialize(responseJson, OFACMockAdapterResponse.class);
        System.debug('responseObj=='+responseObj);
        return responseObj;     
}
}