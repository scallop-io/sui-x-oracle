import * as path from "path";
import { SuiPackagePublisher } from "@scallop-io/sui-package-kit";
import { suiKit } from "./sui-kit";

const publishPackage = async (pkgPath: string) => {
  const signer = suiKit.getSigner();
  const publisher = new SuiPackagePublisher();
  const gasBudget = 10 ** 9;
  return await publisher.publishPackage(pkgPath, signer, {
    gasBudget,
    withUnpublishedDependencies: false,
    skipFetchLatestGitDeps: false
  });
}

const pkgPath = path.join(__dirname, "../test_pyth");
publishPackage(pkgPath).then(console.log).catch(console.error);
