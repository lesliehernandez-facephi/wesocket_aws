import React ,{ createContext, useCallback, useState } from "react";

export const Auth = createContext();

// estado inicial de la aplicacion 

const initialState = {
    uid: null,
    checking: true, //este es para ver si el usuario esta autentificado o no para mostras los datos
    logged: false, //este es para saber si el usuario esta logueado o no
    name: null,
    email: null,
};


export const AuthProvider = ({ childer })=>{

    const [auth, setAuth]  = useState(initialState)

    const login = (email, password ) =>{}

    const regist = (nombre, email, password ) =>{}
    const verificaToken = useCallback(()=>{}, [])

    const logout = () =>{

    }



    return (
        <Auth.Provider value={{
            login,
            regist,
            verificaToken,
            logout

        }}>
            { childer }
        </Auth.Provider>
    )
}