const { redirectToLoginPage, requestTokens } = require('./cognito');

const poolData = {
    UserPoolId: 'eu-west-2_NQCguqJM4',
    ClientId: '3n7im4o5bs90v74cdf89u99ulb',
};

const code = redirectToLoginPage(poolData.ClientId);


requestTokens(poolData.ClientId, code)
    .then(tokens => {
        console.log('tokens', tokens)     
        const username = 'Ericka';        

        document.getElementById('user-info').textContent = username;

        const ws = new WebSocket('wss://hgushs99w4.execute-api.eu-west-2.amazonaws.com/ws_primary');

        ws.onopen = (e) => console.log('opened', e);
        ws.onclose = (e) => console.log('closed', e);
        ws.onerror = (e) => console.error('error', e);
        // Mensaje recibido
        ws.onmessage = (e) => {
            const { username, message } = JSON.parse(e.data);
            if (username && message) {
                appendMessage(username, message);
            }
        }

        const mainForm = document.getElementById('main');

        const messageInput = document.getElementById('message-input');
        // Mensaje enviado

        mainForm.addEventListener("submit", (e) => {
            e.preventDefault();

            const message = messageInput.value;

            const body = {
                action: 'sendmessage',
                payload: {
                    username: username,
                    message
                },
            };

            ws.send(JSON.stringify(body));

            messageInput.value = '';
        });

    });

const createMessageNode = (username, message) => {
    const byMe = true;

    const mainDiv = document.createElement('div');
    const div = document.createElement('div');
    const p = document.createElement('p');
    const span = document.createElement('span');

    mainDiv.className = byMe ? 'outgoing_msg' : 'received_msg';
    div.className = byMe ? 'sent_msg' : 'received_withd_msg';
    p.textContent = message;
    span.textContent = username + ' | ' + new Date().toString();
    span.className = 'time_date';

    /*
    <div className="incoming_msg">
        <div className="received_msg">
            <div className="received_withd_msg">
                <p>Test which is a new approach to have all solutions</p>
                <span className="time_date">Manolo | 11:01 AM    |    June 9</span>
            </div>
        </div>
    </div>
    <div class="outgoing_msg">
        <div class="sent_msg">
            <p>Test which is a new approach to have all solutions</p>
            <span class="time_date"> 11:01 AM    |    June 9</span>
        </div>
    </div>
    */

    div.appendChild(p);
    div.appendChild(span);
    mainDiv.appendChild(div);

    if (byMe) {
        return mainDiv;
    }

    const masterDiv = document.createElement('div');
    masterDiv.className = 'incoming_msg'
    masterDiv.appendChild(mainDiv);
    return masterDiv;
};

const appendMessage = (username, message) => {
    document.getElementById('msg_history').appendChild(createMessageNode(username, message));
};