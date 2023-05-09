import XCTest
import AWSKinesisVideoWebRTCDemoApp

class EventTests: XCTestCase {

    func testParseICECandidateEvent() {
        let testEvent = "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MH0=\",\"messageType\":\"ICE_CANDIDATE\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result?.getAction())
        XCTAssertNotNil(result?.getSenderClientId())
        XCTAssertNotNil(result?.getRecipientClientId())
        XCTAssertNotNil(result?.getMessagePayload)
        
        let actualDecodedMessagePayload = (String((result?.getMessagePayload().base64Decoded()!)!))
        let expectDecodedMessagePayload = "{\"candidate\":\"candidate:4122291481 1 udp 2122260223 192.168.56.162 62065 typ host generation 0 ufrag qA7g network-id 1 network-cost 10\",\"sdpMid\":\"0\",\"sdpMLineIndex\":0}"
        XCTAssertEqual(actualDecodedMessagePayload, expectDecodedMessagePayload)
        
        
        let expectedEncodedMessagePayload = result?.getMessagePayload()
        let actualEncodedMessagePayload = actualDecodedMessagePayload.base64Encoded()
        XCTAssertEqual(actualEncodedMessagePayload, expectedEncodedMessagePayload)
    }
    
    func testParseEventEmpty() {
        let testEvent = ""
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNil(result)
    }
    
    func testEventPayloadExtraStringField() {
        // Payload contains extra field: string key, string value
        let testEvent =
        "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MCwgInRyb2xsIjoieWVzIn0=\",\"messageType\":\"ICE_CANDIDATE\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testEventPayloadExtraNumberField() {
        // Payload contains extra field: string key, number value
        let testEvent =
        "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MCwgIndlZWVlIjpSZWdpb25zLlVTX1dFU1RfMn0=\",\"messageType\":\"ICE_CANDIDATE\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testEventPayloadExtraObjectField() {
        // Payload contains extra field: string key, object value
        let testEvent =
        "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MCwgIndlZWVlIjp7IkhleSIsICJIaSJ9fQ==\",\"messageType\":\"ICE_CANDIDATE\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testEventPayloadExtraArrayField() {
        // Payload contains extra field: string key, array value
        let testEvent =
        "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MCwgIndlZWVlIjogWyJISSIsICJISTIiXX0=\",\"messageType\":\"ICE_CANDIDATE\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testMessageContainsExtraStringField() {
        // Message object contains extra field: string key, string value
        let testEvent = "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MH0=\",\"messageType\":\"ICE_CANDIDATE\",\"Hi\":\"Hi\"}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testMessageContainsExtraNumberField() {
        // Message object contains extra field: string key, number value
        let testEvent = "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MH0=\",\"messageType\":\"ICE_CANDIDATE\",\"Hi\":10}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testMessageContainsExtraObjectField() {
        // Message object contains extra field: string key, object value
        let testEvent = "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MH0=\",\"messageType\":\"ICE_CANDIDATE\",\"Hey\":{\"Hi\":\"No\"}}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testMessageContainsExtraArrayField() {
        // Message object contains extra field: string key, array value
        let testEvent = "{\"messagePayload\":\"eyJjYW5kaWRhdGUiOiJjYW5kaWRhdGU6NDEyMjI5MTQ4MSAxIHVkcCAyMTIyMjYwMjIzIDE5Mi4xNjguNTYuMTYyIDYyMDY1IHR5cCBob3N0IGdlbmVyYXRpb24gMCB1ZnJhZyBxQTdnIG5ldHdvcmstaWQgMSBuZXR3b3JrLWNvc3QgMTAiLCJzZHBNaWQiOiIwIiwic2RwTUxpbmVJbmRleCI6MH0=\",\"messageType\":\"ICE_CANDIDATE\",\"Hi\":[1,2]}"
        let result = Event.parseEvent(event: testEvent)
        XCTAssertNotNil(result)
    }
    
    func testParseSDPOfferEvent() {
        let testOfferEvent = "{\"messagePayload\":\"eyJ0eXBlIjoib2ZmZXIiLCJzZHAiOiJ2PTBcclxubz0tIDM0MTcxMzk5NDEyNjI0OTMyMTAgMiBJTiBJUDQgMTI3LjAuMC4xXHJcbnM9LVxyXG50PTAgMFxyXG5hPWdyb3VwOkJVTkRMRSAwIDFcclxuYT1tc2lkLXNlbWFudGljOiBXTVMgVFFmbDBvM0hMN0piMldPUDRLeHQzNVU4MzFUWUVzZ29qbUtxXHJcbm09YXVkaW8gOSBVRFAvVExTL1JUUC9TQVZQRiAxMTEgMTAzIDEwNCA5IDAgOCAxMDYgMTA1IDEzIDExMCAxMTIgMTEzIDEyNlxyXG5jPUlOIElQNCAwLjAuMC4wXHJcbmE9cnRjcDo5IElOIElQNCAwLjAuMC4wXHJcbmE9aWNlLXVmcmFnOkZ4TkZcclxuYT1pY2UtcHdkOnkyOFBEZzJkMXlvdytkTWs0NzBCNUVjZlxyXG5hPWljZS1vcHRpb25zOnRyaWNrbGVcclxuYT1maW5nZXJwcmludDpzaGEtMjU2IEI3OjYwOkJBOjMwOkREOjA5OjkyOjQzOjU0OjRGOjQxOjlBOkI4OjU5OjYxOjAyOkZBOjk5OkYzOjVBOjI5OjE4OjNCOjQ3OjQ5OjFFOjFBOkMyOjkyOjdEOjMwOkZCXHJcbmE9c2V0dXA6YWN0cGFzc1xyXG5hPW1pZDowXHJcbmE9ZXh0bWFwOjEgdXJuOmlldGY6cGFyYW1zOnJ0cC1oZHJleHQ6c3NyYy1hdWRpby1sZXZlbFxyXG5hPWV4dG1hcDoyIGh0dHA6Ly93d3cud2VicnRjLm9yZy9leHBlcmltZW50cy9ydHAtaGRyZXh0L2Ficy1zZW5kLXRpbWVcclxuYT1leHRtYXA6MyBodHRwOi8vd3d3LmlldGYub3JnL2lkL2RyYWZ0LWhvbG1lci1ybWNhdC10cmFuc3BvcnQtd2lkZS1jYy1leHRlbnNpb25zLTAxXHJcbmE9ZXh0bWFwOjQgdXJuOmlldGY6cGFyYW1zOnJ0cC1oZHJleHQ6c2RlczptaWRcclxuYT1leHRtYXA6NSB1cm46aWV0ZjpwYXJhbXM6cnRwLWhkcmV4dDpzZGVzOnJ0cC1zdHJlYW0taWRcclxuYT1leHRtYXA6NiB1cm46aWV0ZjpwYXJhbXM6cnRwLWhkcmV4dDpzZGVzOnJlcGFpcmVkLXJ0cC1zdHJlYW0taWRcclxuYT1zZW5kcmVjdlxyXG5hPW1zaWQ6VFFmbDBvM0hMN0piMldPUDRLeHQzNVU4MzFUWUVzZ29qbUtxIDE1YTNjNDJmLTU5MTgtNGJjNy1hN2I4LTFmNTQ5MzEwOWY1M1xyXG5hPXJ0Y3AtbXV4XHJcbmE9cnRwbWFwOjExMSBvcHVzLzQ4MDAwLzJcclxuYT1ydGNwLWZiOjExMSB0cmFuc3BvcnQtY2NcclxuYT1mbXRwOjExMSBtaW5wdGltZT0xMDt1c2VpbmJhbmRmZWM9MVxyXG5hPXJ0cG1hcDoxMDMgSVNBQy8xNjAwMFxyXG5hPXJ0cG1hcDoxMDQgSVNBQy8zMjAwMFxyXG5hPXJ0cG1hcDo5IEc3MjIvODAwMFxyXG5hPXJ0cG1hcDowIFBDTVUvODAwMFxyXG5hPXJ0cG1hcDo4IFBDTUEvODAwMFxyXG5hPXJ0cG1hcDoxMDYgQ04vMzIwMDBcclxuYT1ydHBtYXA6MTA1IENOLzE2MDAwXHJcbmE9cnRwbWFwOjEzIENOLzgwMDBcclxuYT1ydHBtYXA6MTEwIHRlbGVwaG9uZS1ldmVudC80ODAwMFxyXG5hPXJ0cG1hcDoxMTIgdGVsZXBob25lLWV2ZW50LzMyMDAwXHJcbmE9cnRwbWFwOjExMyB0ZWxlcGhvbmUtZXZlbnQvMTYwMDBcclxuYT1ydHBtYXA6MTI2IHRlbGVwaG9uZS1ldmVudC84MDAwXHJcbmE9c3NyYzoyODQ4OTU1Nzc0IGNuYW1lOkxvRW81dTM1SHVtT3I3QTRcclxuYT1zc3JjOjI4NDg5NTU3NzQgbXNpZDpUUWZsMG8zSEw3SmIyV09QNEt4dDM1VTgzMVRZRXNnb2ptS3EgMTVhM2M0MmYtNTkxOC00YmM3LWE3YjgtMWY1NDkzMTA5ZjUzXHJcbmE9c3NyYzoyODQ4OTU1Nzc0IG1zbGFiZWw6VFFmbDBvM0hMN0piMldPUDRLeHQzNVU4MzFUWUVzZ29qbUtxXHJcbmE9c3NyYzoyODQ4OTU1Nzc0IGxhYmVsOjE1YTNjNDJmLTU5MTgtNGJjNy1hN2I4LTFmNTQ5MzEwOWY1M1xyXG5tPXZpZGVvIDkgVURQL1RMUy9SVFAvU0FWUEYgOTYgOTcgOTggOTkgMTAwIDEwMSAxMDIgMTIyIDEyNyAxMjEgMTI1IDEwNyAxMDggMTA5IDEyNCAxMjAgMTIzIDExOSAxMTQgMTE1IDExNlxyXG5jPUlOIElQNCAwLjAuMC4wXHJcbmE9cnRjcDo5IElOIElQNCAwLjAuMC4wXHJcbmE9aWNlLXVmcmFnOkZ4TkZcclxuYT1pY2UtcHdkOnkyOFBEZzJkMXlvdytkTWs0NzBCNUVjZlxyXG5hPWljZS1vcHRpb25zOnRyaWNrbGVcclxuYT1maW5nZXJwcmludDpzaGEtMjU2IEI3OjYwOkJBOjMwOkREOjA5OjkyOjQzOjU0OjRGOjQxOjlBOkI4OjU5OjYxOjAyOkZBOjk5OkYzOjVBOjI5OjE4OjNCOjQ3OjQ5OjFFOjFBOkMyOjkyOjdEOjMwOkZCXHJcbmE9c2V0dXA6YWN0cGFzc1xyXG5hPW1pZDoxXHJcbmE9ZXh0bWFwOjE0IHVybjppZXRmOnBhcmFtczpydHAtaGRyZXh0OnRvZmZzZXRcclxuYT1leHRtYXA6MiBodHRwOi8vd3d3LndlYnJ0Yy5vcmcvZXhwZXJpbWVudHMvcnRwLWhkcmV4dC9hYnMtc2VuZC10aW1lXHJcbmE9ZXh0bWFwOjEzIHVybjozZ3BwOnZpZGVvLW9yaWVudGF0aW9uXHJcbmE9ZXh0bWFwOjMgaHR0cDovL3d3dy5pZXRmLm9yZy9pZC9kcmFmdC1ob2xtZXItcm1jYXQtdHJhbnNwb3J0LXdpZGUtY2MtZXh0ZW5zaW9ucy0wMVxyXG5hPWV4dG1hcDoxMiBodHRwOi8vd3d3LndlYnJ0Yy5vcmcvZXhwZXJpbWVudHMvcnRwLWhkcmV4dC9wbGF5b3V0LWRlbGF5XHJcbmE9ZXh0bWFwOjExIGh0dHA6Ly93d3cud2VicnRjLm9yZy9leHBlcmltZW50cy9ydHAtaGRyZXh0L3ZpZGVvLWNvbnRlbnQtdHlwZVxyXG5hPWV4dG1hcDo3IGh0dHA6Ly93d3cud2VicnRjLm9yZy9leHBlcmltZW50cy9ydHAtaGRyZXh0L3ZpZGVvLXRpbWluZ1xyXG5hPWV4dG1hcDo4IGh0dHA6Ly90b29scy5pZXRmLm9yZy9odG1sL2RyYWZ0LWlldGYtYXZ0ZXh0LWZyYW1lbWFya2luZy0wN1xyXG5hPWV4dG1hcDo5IGh0dHA6Ly93d3cud2VicnRjLm9yZy9leHBlcmltZW50cy9ydHAtaGRyZXh0L2NvbG9yLXNwYWNlXHJcbmE9ZXh0bWFwOjQgdXJuOmlldGY6cGFyYW1zOnJ0cC1oZHJleHQ6c2RlczptaWRcclxuYT1leHRtYXA6NSB1cm46aWV0ZjpwYXJhbXM6cnRwLWhkcmV4dDpzZGVzOnJ0cC1zdHJlYW0taWRcclxuYT1leHRtYXA6NiB1cm46aWV0ZjpwYXJhbXM6cnRwLWhkcmV4dDpzZGVzOnJlcGFpcmVkLXJ0cC1zdHJlYW0taWRcclxuYT1zZW5kcmVjdlxyXG5hPW1zaWQ6VFFmbDBvM0hMN0piMldPUDRLeHQzNVU4MzFUWUVzZ29qbUtxIGE2NGUxZjEzLTJmNWItNGU3ZS1hZWNjLTdlM2I0MTIwZmQ3OFxyXG5hPXJ0Y3AtbXV4XHJcbmE9cnRjcC1yc2l6ZVxyXG5hPXJ0cG1hcDo5NiBWUDgvOTAwMDBcclxuYT1ydGNwLWZiOjk2IGdvb2ctcmVtYlxyXG5hPXJ0Y3AtZmI6OTYgdHJhbnNwb3J0LWNjXHJcbmE9cnRjcC1mYjo5NiBjY20gZmlyXHJcbmE9cnRjcC1mYjo5NiBuYWNrXHJcbmE9cnRjcC1mYjo5NiBuYWNrIHBsaVxyXG5hPXJ0cG1hcDo5NyBydHgvOTAwMDBcclxuYT1mbXRwOjk3IGFwdD05NlxyXG5hPXJ0cG1hcDo5OCBWUDkvOTAwMDBcclxuYT1ydGNwLWZiOjk4IGdvb2ctcmVtYlxyXG5hPXJ0Y3AtZmI6OTggdHJhbnNwb3J0LWNjXHJcbmE9cnRjcC1mYjo5OCBjY20gZmlyXHJcbmE9cnRjcC1mYjo5OCBuYWNrXHJcbmE9cnRjcC1mYjo5OCBuYWNrIHBsaVxyXG5hPWZtdHA6OTggcHJvZmlsZS1pZD0wXHJcbmE9cnRwbWFwOjk5IHJ0eC85MDAwMFxyXG5hPWZtdHA6OTkgYXB0PTk4XHJcbmE9cnRwbWFwOjEwMCBWUDkvOTAwMDBcclxuYT1ydGNwLWZiOjEwMCBnb29nLXJlbWJcclxuYT1ydGNwLWZiOjEwMCB0cmFuc3BvcnQtY2NcclxuYT1ydGNwLWZiOjEwMCBjY20gZmlyXHJcbmE9cnRjcC1mYjoxMDAgbmFja1xyXG5hPXJ0Y3AtZmI6MTAwIG5hY2sgcGxpXHJcbmE9Zm10cDoxMDAgcHJvZmlsZS1pZD0yXHJcbmE9cnRwbWFwOjEwMSBydHgvOTAwMDBcclxuYT1mbXRwOjEwMSBhcHQ9MTAwXHJcbmE9cnRwbWFwOjEwMiBIMjY0LzkwMDAwXHJcbmE9cnRjcC1mYjoxMDIgZ29vZy1yZW1iXHJcbmE9cnRjcC1mYjoxMDIgdHJhbnNwb3J0LWNjXHJcbmE9cnRjcC1mYjoxMDIgY2NtIGZpclxyXG5hPXJ0Y3AtZmI6MTAyIG5hY2tcclxuYT1ydGNwLWZiOjEwMiBuYWNrIHBsaVxyXG5hPWZtdHA6MTAyIGxldmVsLWFzeW1tZXRyeS1hbGxvd2VkPTE7cGFja2V0aXphdGlvbi1tb2RlPTE7cHJvZmlsZS1sZXZlbC1pZD00MjAwMWZcclxuYT1ydHBtYXA6MTIyIHJ0eC85MDAwMFxyXG5hPWZtdHA6MTIyIGFwdD0xMDJcclxuYT1ydHBtYXA6MTI3IEgyNjQvOTAwMDBcclxuYT1ydGNwLWZiOjEyNyBnb29nLXJlbWJcclxuYT1ydGNwLWZiOjEyNyB0cmFuc3BvcnQtY2NcclxuYT1ydGNwLWZiOjEyNyBjY20gZmlyXHJcbmE9cnRjcC1mYjoxMjcgbmFja1xyXG5hPXJ0Y3AtZmI6MTI3IG5hY2sgcGxpXHJcbmE9Zm10cDoxMjcgbGV2ZWwtYXN5bW1ldHJ5LWFsbG93ZWQ9MTtwYWNrZXRpemF0aW9uLW1vZGU9MDtwcm9maWxlLWxldmVsLWlkPTQyMDAxZlxyXG5hPXJ0cG1hcDoxMjEgcnR4LzkwMDAwXHJcbmE9Zm10cDoxMjEgYXB0PTEyN1xyXG5hPXJ0cG1hcDoxMjUgSDI2NC85MDAwMFxyXG5hPXJ0Y3AtZmI6MTI1IGdvb2ctcmVtYlxyXG5hPXJ0Y3AtZmI6MTI1IHRyYW5zcG9ydC1jY1xyXG5hPXJ0Y3AtZmI6MTI1IGNjbSBmaXJcclxuYT1ydGNwLWZiOjEyNSBuYWNrXHJcbmE9cnRjcC1mYjoxMjUgbmFjayBwbGlcclxuYT1mbXRwOjEyNSBsZXZlbC1hc3ltbWV0cnktYWxsb3dlZD0xO3BhY2tldGl6YXRpb24tbW9kZT0xO3Byb2ZpbGUtbGV2ZWwtaWQ9NDJlMDFmXHJcbmE9cnRwbWFwOjEwNyBydHgvOTAwMDBcclxuYT1mbXRwOjEwNyBhcHQ9MTI1XHJcbmE9cnRwbWFwOjEwOCBIMjY0LzkwMDAwXHJcbmE9cnRjcC1mYjoxMDggZ29vZy1yZW1iXHJcbmE9cnRjcC1mYjoxMDggdHJhbnNwb3J0LWNjXHJcbmE9cnRjcC1mYjoxMDggY2NtIGZpclxyXG5hPXJ0Y3AtZmI6MTA4IG5hY2tcclxuYT1ydGNwLWZiOjEwOCBuYWNrIHBsaVxyXG5hPWZtdHA6MTA4IGxldmVsLWFzeW1tZXRyeS1hbGxvd2VkPTE7cGFja2V0aXphdGlvbi1tb2RlPTA7cHJvZmlsZS1sZXZlbC1pZD00MmUwMWZcclxuYT1ydHBtYXA6MTA5IHJ0eC85MDAwMFxyXG5hPWZtdHA6MTA5IGFwdD0xMDhcclxuYT1ydHBtYXA6MTI0IEgyNjQvOTAwMDBcclxuYT1ydGNwLWZiOjEyNCBnb29nLXJlbWJcclxuYT1ydGNwLWZiOjEyNCB0cmFuc3BvcnQtY2NcclxuYT1ydGNwLWZiOjEyNCBjY20gZmlyXHJcbmE9cnRjcC1mYjoxMjQgbmFja1xyXG5hPXJ0Y3AtZmI6MTI0IG5hY2sgcGxpXHJcbmE9Zm10cDoxMjQgbGV2ZWwtYXN5bW1ldHJ5LWFsbG93ZWQ9MTtwYWNrZXRpemF0aW9uLW1vZGU9MTtwcm9maWxlLWxldmVsLWlkPTRkMDAzMlxyXG5hPXJ0cG1hcDoxMjAgcnR4LzkwMDAwXHJcbmE9Zm10cDoxMjAgYXB0PTEyNFxyXG5hPXJ0cG1hcDoxMjMgSDI2NC85MDAwMFxyXG5hPXJ0Y3AtZmI6MTIzIGdvb2ctcmVtYlxyXG5hPXJ0Y3AtZmI6MTIzIHRyYW5zcG9ydC1jY1xyXG5hPXJ0Y3AtZmI6MTIzIGNjbSBmaXJcclxuYT1ydGNwLWZiOjEyMyBuYWNrXHJcbmE9cnRjcC1mYjoxMjMgbmFjayBwbGlcclxuYT1mbXRwOjEyMyBsZXZlbC1hc3ltbWV0cnktYWxsb3dlZD0xO3BhY2tldGl6YXRpb24tbW9kZT0xO3Byb2ZpbGUtbGV2ZWwtaWQ9NjQwMDMyXHJcbmE9cnRwbWFwOjExOSBydHgvOTAwMDBcclxuYT1mbXRwOjExOSBhcHQ9MTIzXHJcbmE9cnRwbWFwOjExNCByZWQvOTAwMDBcclxuYT1ydHBtYXA6MTE1IHJ0eC85MDAwMFxyXG5hPWZtdHA6MTE1IGFwdD0xMTRcclxuYT1ydHBtYXA6MTE2IHVscGZlYy85MDAwMFxyXG5hPXNzcmMtZ3JvdXA6RklEIDExMjIwNTk2MjggMTgzNTUzMjk4MlxyXG5hPXNzcmM6MTEyMjA1OTYyOCBjbmFtZTpMb0VvNXUzNUh1bU9yN0E0XHJcbmE9c3NyYzoxMTIyMDU5NjI4IG1zaWQ6VFFmbDBvM0hMN0piMldPUDRLeHQzNVU4MzFUWUVzZ29qbUtxIGE2NGUxZjEzLTJmNWItNGU3ZS1hZWNjLTdlM2I0MTIwZmQ3OFxyXG5hPXNzcmM6MTEyMjA1OTYyOCBtc2xhYmVsOlRRZmwwbzNITDdKYjJXT1A0S3h0MzVVODMxVFlFc2dvam1LcVxyXG5hPXNzcmM6MTEyMjA1OTYyOCBsYWJlbDphNjRlMWYxMy0yZjViLTRlN2UtYWVjYy03ZTNiNDEyMGZkNzhcclxuYT1zc3JjOjE4MzU1MzI5ODIgY25hbWU6TG9FbzV1MzVIdW1PcjdBNFxyXG5hPXNzcmM6MTgzNTUzMjk4MiBtc2lkOlRRZmwwbzNITDdKYjJXT1A0S3h0MzVVODMxVFlFc2dvam1LcSBhNjRlMWYxMy0yZjViLTRlN2UtYWVjYy03ZTNiNDEyMGZkNzhcclxuYT1zc3JjOjE4MzU1MzI5ODIgbXNsYWJlbDpUUWZsMG8zSEw3SmIyV09QNEt4dDM1VTgzMVRZRXNnb2ptS3FcclxuYT1zc3JjOjE4MzU1MzI5ODIgbGFiZWw6YTY0ZTFmMTMtMmY1Yi00ZTdlLWFlY2MtN2UzYjQxMjBmZDc4XHJcbiJ9\",\"messageType\":\"SDP_OFFER\",\"senderClientId\":\"ConsumerViewer\"}"
        let result = Event.parseEvent(event: testOfferEvent)
        XCTAssertNotNil(result?.getAction())
        XCTAssertEqual(result?.getAction(), offerAction)
        XCTAssertNotNil(result?.getSenderClientId())
        XCTAssertNotNil(result?.getRecipientClientId())
        XCTAssertNotNil(result?.getMessagePayload)
    }
}
