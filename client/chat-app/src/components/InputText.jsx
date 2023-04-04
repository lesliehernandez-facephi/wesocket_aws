import React from 'react';


const InputText = () => {
  return (
    <div className='inputText'>
      <input type="text" placeholder='Escribe......' />
      <div className="send">
        <img src="https://raw.githubusercontent.com/safak/youtube2022/react-chat/src/img/attach.png" alt="" />
        <input type="file" style={{display:"none"}} id='file'/>
        <label htmlFor="file">
          <img src="https://raw.githubusercontent.com/safak/youtube2022/react-chat/src/img/img.png" alt="" />
        </label>
        <button>Send</button>
      </div>
    </div> 
  )
}

export default InputText 