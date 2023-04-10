import React from 'react';

const ListChat = () => {
    return (
    <div className='chats'>
        <div className='userChat'>
            <img src="favicon.ico" alt=""/>
            <div className="userChatInfo">
                <span>Janet Johnose</span>
                <br/>
               
                <span className="success" style={{color: "green"}}>Online</span>
                   <span className="danger" style={{color: "red"}}>Offline</span>
            </div>
        </div>
    </div> 
    )
  }
  
  export default ListChat