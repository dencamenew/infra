"use client"

import { useLogin } from "@/hooks/api/useLogin"
import { useLanguage } from "@/hooks/useLanguage";
import { translations } from "@/lib/translations";
import { FormEvent, useMemo, useState } from "react";
import { Input } from "../ui/input";
import { Button } from "../ui/button";

export default function AuthModule() {
  const auth = useLogin();
  const { lang } = useLanguage();
  const t = useMemo(() => translations[lang], [lang]);

  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [password, setPassword] = useState("");
  const [maxId, setMaxId] = useState("");
  const [errorText, setErrorText] = useState("");

  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErrorText("");
    auth.mutate(
      { firstName, lastName, password, maxId },
      {
        onError: (error) => {
          const text = error instanceof Error ? error.message : t.connectionError;
          setErrorText(text);
        },
      },
    );
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center px-4">
      <div className="w-full max-w-sm space-y-5">
        <div className="space-y-1 text-center">
          <h1 className="text-2xl font-semibold">{t.welcome}</h1>
          <p className="text-sm text-muted-foreground">{t.enterCredentials}</p>
        </div>

        <form className="space-y-3" onSubmit={onSubmit}>
          <Input
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            placeholder={t.firstNamePlaceholder}
            autoComplete="given-name"
            disabled={auth.isPending}
          />
          <Input
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            placeholder={t.lastNamePlaceholder}
            autoComplete="family-name"
            disabled={auth.isPending}
          />
          <Input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            placeholder={t.passwordPlaceholder}
            autoComplete="current-password"
            disabled={auth.isPending}
          />
          <Input
            value={maxId}
            onChange={(e) => setMaxId(e.target.value)}
            placeholder={t.maxIdPlaceholder}
            autoComplete="off"
            disabled={auth.isPending}
          />
          <Button type="submit" className="w-full" disabled={auth.isPending}>
            {auth.isPending ? t.loggingIn : t.login}
          </Button>
        </form>

        {errorText ? (
          <p className="text-sm text-center text-destructive">{errorText}</p>
        ) : null}
      </div>
    </div>
  );
}
