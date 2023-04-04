package models

// estructura para guardar informacion sobre las salas que se crean
type Room struct {
	Name          string
	ConnectionIDs []string
}

type RoomDynamodb struct {
	Name          string   `json:"name"`
	ConnectionIDs []string `json:"connection_ids"`
}

type RoomMessages struct {
	RoomName string `json:"room_name"`
	// Payload		Payload
}
