import React from 'react';
import Messagess from './Messagess'
import InputText from './InputText'

const Chat = () => {
    return (
      <div className='chat'>
        <div className="chatInfo">
          <span>Jane</span>
          <div className="chatIcon">
            <img src="https://raw.githubusercontent.com/safak/youtube2022/react-chat/src/img/add.png" alt="add user" />
            <img src="https://raw.githubusercontent.com/safak/youtube2022/react-chat/src/img/more.png" alt="ajustes" />
            {/* <img src="https://cdn.icon-icons.com/icons2/1875/PNG/512/plus_120249.png" alt="" height='58px'/> */}
          </div>

        </div>
        <Messagess/>
        <InputText/>
      </div> 
    )
  }
  
  export default Chat