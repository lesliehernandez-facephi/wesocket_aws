import React from 'react';
import Navbar from './Navbar';
import Search from './Search';
import ListChat from './ListChat';

const Sidebar = () => {
    return (
      <div className='sidebar'>
        <Navbar/>
        <Search/>
        <ListChat/>
      </div> 
    )
  }
  
  export default Sidebar 