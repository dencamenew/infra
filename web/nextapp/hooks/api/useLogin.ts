import { useMutation } from "@tanstack/react-query";
import { useToken } from "../useAuth";
import { useFetch } from "./useFetch";

interface CredentialsLoginPayload {
    firstName: string;
    lastName: string;
    password: string;
    maxId: string;
}

function getErrorMessage(payload: unknown): string {
    if (!payload || typeof payload !== "object") {
        return "Login request failed";
    }

    const source = payload as {
        detail?: { message?: string } | string;
        message?: string;
    };

    if (typeof source.detail === "string") {
        return source.detail;
    }

    if (source.detail && typeof source.detail === "object" && typeof source.detail.message === "string") {
        return source.detail.message;
    }

    if (typeof source.message === "string") {
        return source.message;
    }

    return "Login request failed";
}

export function useLogin() {
    const { setToken } = useToken();
    const fetch = useFetch();

    const handleAuth = useMutation({
        mutationFn: async (payload: CredentialsLoginPayload) => {
            const firstName = payload.firstName.trim();
            const lastName = payload.lastName.trim();
            const password = payload.password;
            const maxId = payload.maxId.trim();

            if (!firstName || !lastName || !password || !maxId) {
                throw new Error("Все поля обязательны");
            }

            const authResponse = await fetch("/auth/login_user", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: 'include',
                body: JSON.stringify({
                    first_name: firstName,
                    last_name: lastName,
                    password,
                }),
            });

            if (!authResponse.ok) {
                const errorPayload = await authResponse.json().catch(() => null);
                throw new Error(getErrorMessage(errorPayload));
            }

            const authData = await authResponse.json().catch(() => ({} as { max_id?: string }));
            const effectiveMaxId = typeof authData.max_id === "string" && authData.max_id.length > 0
                ? authData.max_id
                : maxId;

            // Bind entered MAX_id for users that do not have one in DB yet.
            if (!authData.max_id) {
                await fetch("/auth/register", {
                    method: "PUT",
                    headers: { "Content-Type": "application/json" },
                    credentials: 'include',
                    body: JSON.stringify({
                        first_name: firstName,
                        last_name: lastName,
                        password,
                        max_id: effectiveMaxId,
                    }),
                });
            }

            const tokenResponse = await fetch("/auth/login_max_id", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: 'include',
                body: JSON.stringify({
                    max_id: effectiveMaxId,
                }),
            });

            if (!tokenResponse.ok) {
                const errorPayload = await tokenResponse.json().catch(() => null);
                throw new Error(getErrorMessage(errorPayload));
            }

            return tokenResponse.json();
        },
        onSuccess: (data: { access_token: string }) => {
            localStorage.setItem("token", data.access_token);
            setToken(data.access_token);
        },
    });

    return handleAuth;
};
