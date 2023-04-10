 const axios = require("axios");

const redirectToLoginPage = (clientId) => {
    const queryParams = new URLSearchParams(window.location.search);
    const code = queryParams.get('code');

    if (typeof code !== 'string') {
        const redirectTo =  'https://chat-go.auth.eu-west-2.amazoncognito.com/login'
            + `?client_id=` + encodeURIComponent(clientId)
            + '&response_type=code'
            + '&scope=email+openid+phone'
            + '&redirect_uri=' + encodeURIComponent(window.location.origin);        

        window.location.href = redirectTo;
    }

    return code;
};

const requestTokens = (clientId, code) => {
    const data = {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': code,
        'redirect_uri': window.location.origin
    }
    return axios.post(
        'https://chat-go.auth.eu-west-2.amazoncognito.com/oauth2/token',
        new URLSearchParams(data).toString(),        
        {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        }        
    ).then(res => res.data);
};

module.exports = {
    redirectToLoginPage,
    requestTokens
};