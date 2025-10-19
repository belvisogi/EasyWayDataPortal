// easyway-portal-api/src/server.ts
import "./observability/tracing";
import app from "./app";

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`EasyWay API running on port ${PORT}`);
});
