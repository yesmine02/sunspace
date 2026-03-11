const http = require('http');

http.get('http://193.111.250.244:3046/api/users?populate=*', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        const json = JSON.parse(data);
        require('fs').writeFileSync('users.json', JSON.stringify(json, null, 2));
    });
});
