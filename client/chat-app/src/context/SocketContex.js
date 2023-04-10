import React, { useContext, useEffect } from 'react';
import { createContext } from 'react';
import Auth from '../auth/Auth'
import { useSocket } from '../hooks/useSocket'

export const SocketContext = createContext();


export const SocketProvider = ({ children }) => {

    const { socket, online, conectarSocket, desconectarSocket } = useSocket('http://localhost:8080');
    const {auth} = useContext(Auth)

    useEffect(()=>{
        if(auth.logged) {
            conectarSocket()
        }
    }, [auth, conectarSocket])


    useEffect(()=>{
        if(!auth.logged) {
            desconectarSocket()
        }
    }, [auth, desconectarSocket])
    
    return (
        <SocketContext.Provider value={{ socket, online }}>
            { children }
        </SocketContext.Provider>
    )
}
