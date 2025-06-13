// WebSocket
app.get('/api/ws', webSocketController.handleWebSocket());
app.post('/api/websocket/notify', authMiddleware.authRequired, webSocketController.handleNotify); 